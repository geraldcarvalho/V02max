import AVFoundation
import HIDITCore

/// Cue tones, synthesized once into buffers and scheduled ahead of time on an AVAudioEngine.
///
/// Every upcoming cue is queued at an exact host time when a run starts or resumes, so tones land on
/// time even when the main thread is busy or the screen is locked. A silent loop keeps the audio session
/// active during a run so the app keeps running in the background.
final class AudioCues {
    private let engine = AVAudioEngine()
    private let cueNode = AVAudioPlayerNode()
    private let keepAliveNode = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var cache: [String: AVAudioPCMBuffer] = [:]
    private var cachedBoost = false

    init() {
        engine.attach(cueNode)
        engine.attach(keepAliveNode)
        engine.connect(cueNode, to: engine.mainMixerNode, format: format)
        engine.connect(keepAliveNode, to: engine.mainMixerNode, format: format)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    /// Activates the playback session and starts the engine and the silent keep-alive loop.
    func begin() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        startEngineIfNeeded()
        if !keepAliveNode.isPlaying, let silence = silentBuffer() {
            keepAliveNode.scheduleBuffer(silence, at: nil, options: .loops)
            keepAliveNode.play()
        }
    }

    func end() {
        cueNode.stop()
        keepAliveNode.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Drops every queued cue and queues `cues`, each at a delay in seconds from now.
    func schedule(_ cues: [(delay: TimeInterval, cue: Cue)], boost: Bool) {
        startEngineIfNeeded()
        cueNode.stop()
        let nowHost = mach_absolute_time()
        for item in cues where item.delay >= -0.05 {
            guard let buffer = buffer(for: item.cue, boost: boost) else { continue }
            let when = AVAudioTime(hostTime: nowHost + AVAudioTime.hostTime(forSeconds: max(0, item.delay)))
            cueNode.scheduleBuffer(buffer, at: when, options: [], completionHandler: nil)
        }
        cueNode.play()
    }

    func cancelScheduled() {
        cueNode.stop()
    }

    /// Plays one cue now, for the test buttons in Settings.
    func playNow(_ cue: Cue, boost: Bool) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        startEngineIfNeeded()
        guard let buffer = buffer(for: cue, boost: boost) else { return }
        cueNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        cueNode.play()
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        engine.prepare()
        try? engine.start()
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        startEngineIfNeeded()
        NotificationCenter.default.post(name: .audioCuesNeedReschedule, object: nil)
    }

    // MARK: Synthesis

    /// A tone: frequency (optionally sweeping to `to`), length, peak volume and start offset in seconds.
    private struct Tone {
        var freq: Double
        var to: Double? = nil
        var duration: Double
        var volume: Double
        var at: Double = 0
    }

    private func tones(for cue: Cue) -> [Tone] {
        switch cue {
        case .runStart:
            return [Tone(freq: 1047, duration: 0.09, volume: 0.35), Tone(freq: 1319, duration: 0.12, volume: 0.35, at: 0.16)]
        case .recoverStart:
            return [Tone(freq: 520, to: 340, duration: 0.7, volume: 0.28)]
        case .tickIntoRecover:
            return [Tone(freq: 1245, duration: 0.06, volume: 0.3)]
        case .tickIntoRun:
            return [Tone(freq: 660, duration: 0.06, volume: 0.18)]
        case .countdownTick:
            return [Tone(freq: 820, duration: 0.03, volume: 0.12)]
        case .countdownBeep(let n):
            // Rising: 3 is lowest, 1 is highest.
            let freq: Double = n >= 3 ? 880 : (n == 2 ? 1047 : 1245)
            return [Tone(freq: freq, duration: 0.1, volume: 0.32)]
        case .finish:
            return [Tone(freq: 784, duration: 0.16, volume: 0.35), Tone(freq: 988, duration: 0.16, volume: 0.35, at: 0.2), Tone(freq: 1319, duration: 0.3, volume: 0.35, at: 0.4)]
        }
    }

    private func key(for cue: Cue) -> String {
        switch cue {
        case .runStart: return "run"
        case .recoverStart: return "recover"
        case .tickIntoRecover: return "tickRise"
        case .tickIntoRun: return "tickFlat"
        case .countdownTick: return "softTick"
        case .countdownBeep(let n): return "beep\(min(3, max(1, n)))"
        case .finish: return "finish"
        }
    }

    private func buffer(for cue: Cue, boost: Bool) -> AVAudioPCMBuffer? {
        if boost != cachedBoost {
            cache.removeAll()
            cachedBoost = boost
        }
        let k = key(for: cue)
        if let b = cache[k] { return b }
        let b = render(tones(for: cue), boost: boost)
        cache[k] = b
        return b
    }

    private func render(_ tones: [Tone], boost: Bool) -> AVAudioPCMBuffer? {
        let rate = format.sampleRate
        let length = (tones.map { $0.at + $0.duration }.max() ?? 0) + 0.02
        let frames = AVAudioFrameCount(length * rate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames), let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for i in 0..<Int(frames) { data[i] = 0 }
        let gain = boost ? 1.8 : 1.0
        for tone in tones {
            let start = Int(tone.at * rate)
            let count = Int(tone.duration * rate)
            let peak = min(1.0, tone.volume * gain)
            let attack = 0.01
            let floor = 0.0001
            var phase = 0.0
            for j in 0..<count where start + j < Int(frames) {
                let t = Double(j) / rate
                let freq = tone.to.map { tone.freq + ($0 - tone.freq) * t / tone.duration } ?? tone.freq
                phase += 2 * .pi * freq / rate
                let env: Double
                if t < attack {
                    env = peak * t / attack
                } else {
                    env = peak * exp(log(floor / peak) * (t - attack) / max(0.001, tone.duration - attack))
                }
                data[start + j] += Float(sin(phase) * env)
            }
        }
        for i in 0..<Int(frames) { data[i] = max(-1, min(1, data[i])) }
        return buffer
    }

    private func silentBuffer() -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(frames) { data[i] = 0 }
        }
        return buffer
    }
}

extension Notification.Name {
    static let audioCuesNeedReschedule = Notification.Name("audioCuesNeedReschedule")
}
