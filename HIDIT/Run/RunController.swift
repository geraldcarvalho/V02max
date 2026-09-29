import SwiftUI
import UIKit
import HIDITCore

struct RunSummary: Equatable {
    var workoutName: String
    var stepsCompleted: Int
    /// Steps in one round; nil when the workout repeats until the person stops.
    var totalSteps: Int?
    var totalSeconds: Int
    var longestWork: Int
    var workSeconds: Int
    var recoverSeconds: Int

    init(workoutName: String, stats: RunStats, totalSteps: Int?) {
        self.workoutName = workoutName
        self.stepsCompleted = stats.steps
        self.totalSteps = totalSteps
        self.totalSeconds = stats.totalSeconds
        self.longestWork = stats.longestWork
        self.workSeconds = stats.workSeconds
        self.recoverSeconds = stats.recoverSeconds
    }
}

/// Drives a run: owns the session, reads the monotonic clock, and routes cues to sound, haptics,
/// voice, the Live Activity and background notifications.
@MainActor
final class RunController: ObservableObject {
    static let shared = RunController()

    @Published private(set) var session: RunSession?
    @Published private(set) var snapshot: RunSession.Snapshot?
    @Published private(set) var workoutName = ""
    @Published private(set) var summary: RunSummary?

    /// Set by the app at launch.
    var settings: AppSettings?

    private let clock = ContinuousClock()
    private let origin: ContinuousClock.Instant
    private let audio = AudioCues()
    private let haptics = HapticCues()
    private let voice = VoiceCues()
    private let activity = LiveActivityManager()
    private let notifications = PhaseNotifications()
    private var timer: Timer?
    private var lastScheduleTime: TimeInterval = 0
    private var firedStart = false
    private var lastPhaseIndex: Int?
    private var lastPaused = false
    private var lastResumeSecond: Int?
    private var activityNeedsUpdate = false
    private var isForeground = true
    private var observers: [NSObjectProtocol] = []

    private init() {
        origin = clock.now
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.didEnterBackground() }
        })
        observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.willEnterForeground() }
        })
        observers.append(center.addObserver(forName: .audioCuesNeedReschedule, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.rescheduleAudio() }
        })
    }

    var isActive: Bool {
        guard let state = session?.state else { return false }
        return state == .running || state == .paused
    }

    /// Monotonic seconds. ContinuousClock keeps counting while the device sleeps.
    func now() -> TimeInterval {
        let d = origin.duration(to: clock.now)
        return Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
    }

    // MARK: Controls

    func start() {
        guard let settings else { return }
        let intervals = settings.intervals
        guard !intervals.isEmpty else { return }
        // HIDIT repeats its ladder until the person stops; the other workouts run once.
        let repeats = settings.selectedPreset == .hidit
        let schedule = Schedule(intervals: intervals, countdown: settings.countdownLength, rounds: repeats ? Schedule.repeatingRounds : 1)
        session = RunSession(schedule: schedule, options: CueOptions(ticks: settings.countdownTicks), startedAt: now())
        workoutName = settings.selectedPreset.name
        summary = nil
        lastScheduleTime = 0
        firedStart = false
        lastPhaseIndex = nil
        lastPaused = false
        lastResumeSecond = nil
        UIApplication.shared.isIdleTimerDisabled = true
        audio.begin()
        haptics.prepare()
        notifications.requestAuthorization()
        rescheduleAudio()
        tick()
        if let state = activityState() {
            activity.start(workoutName: workoutName, state: state)
        }
        startTimer()
    }

    func pause() {
        guard var s = session, s.state == .running else { return }
        s.pause(at: now())
        session = s
        if s.state == .cancelled {
            stop()
            return
        }
        audio.cancelScheduled()
        voice.stop()
        notifications.cancel()
        tick()
    }

    func resume() {
        guard var s = session, s.state == .paused else { return }
        s.resume(at: now())
        session = s
        lastResumeSecond = nil
        activityNeedsUpdate = true
        audio.begin()
        rescheduleAudio()
        if !isForeground { scheduleNotifications() }
        tick()
    }

    func skipCountdown() {
        guard var s = session else { return }
        let n = now()
        s.skipCountdown(at: n)
        session = s
        // Skip the countdown's cues but keep the run cue at the new position.
        lastScheduleTime = s.scheduleTime(at: n) - 0.0001
        firedStart = true
        rescheduleAudio()
        tick()
    }

    /// Ends the run after an interval has started and shows what was done; in the countdown it just cancels.
    func endEarly() {
        guard let s = session else { return }
        let t = s.scheduleTime(at: now())
        let stats = s.schedule.stats(at: t)
        guard stats.workSeconds > 0 else {
            stop()
            return
        }
        audio.playNow(.finish, boost: settings?.volumeBoost ?? false)
        finishWith(stats, of: s)
    }

    /// Cancels the run without a summary.
    func stop() {
        stopTimer()
        session = nil
        snapshot = nil
        audio.end()
        voice.stop()
        activity.end()
        notifications.cancel()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func dismissSummary() {
        summary = nil
    }

    /// Plays a cue now, for the test buttons in Settings.
    func test(_ cue: Cue) {
        guard let settings else { return }
        if settings.sound == .on { audio.playNow(cue, boost: settings.volumeBoost) }
        if settings.sound == .voice { voice.speak(cue) }
        if settings.haptics {
            haptics.prepare()
            haptics.play(cue)
        }
    }

    // MARK: Clock

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard var s = session else {
            stopTimer()
            return
        }
        let n = now()
        let justFinished = s.update(at: n)
        let snap = s.snapshot(at: n)
        session = s
        snapshot = snap

        if s.state == .running || justFinished {
            let t = snap.scheduleTime
            let crossed = s.cues.between(lastScheduleTime, t, includeLower: !firedStart)
            firedStart = true
            lastScheduleTime = t
            // After a long gap (the app was suspended), skip stale cues instead of firing them all at once.
            for event in crossed where t - event.time < 1 {
                fireLive(event.cue)
            }
            if let r = snap.resumeCountdown {
                let second = TimeFormat.displaySeconds(r)
                if second != lastResumeSecond {
                    lastResumeSecond = second
                    fireLive(.countdownBeep(second), voice: false)
                }
            } else {
                lastResumeSecond = nil
            }
        }

        let paused = s.state == .paused
        if snap.phaseIndex != lastPhaseIndex || paused != lastPaused || activityNeedsUpdate {
            activityNeedsUpdate = false
            lastPhaseIndex = snap.phaseIndex
            lastPaused = paused
            if let state = activityState() { activity.update(state) }
        }

        if justFinished { complete(s) }
    }

    /// Haptics and voice fire as the clock crosses a cue. Tones are already queued on the audio engine.
    private func fireLive(_ cue: Cue, voice speak: Bool = true) {
        guard let settings else { return }
        if settings.haptics && isForeground { haptics.play(cue) }
        if speak && settings.sound == .voice { voice.speak(cue) }
    }

    private func complete(_ s: RunSession) {
        finishWith(s.schedule.stats(at: s.schedule.totalDuration), of: s)
    }

    private func finishWith(_ stats: RunStats, of s: RunSession) {
        stopTimer()
        let repeats = s.schedule.rounds > 1
        summary = RunSummary(workoutName: workoutName, stats: stats, totalSteps: repeats ? nil : s.schedule.intervals.count)
        activity.end()
        notifications.cancel()
        UIApplication.shared.isIdleTimerDisabled = false
        session = nil
        snapshot = nil
        // Let the finish chime play before releasing the audio session.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.session == nil else { return }
            self.audio.end()
        }
    }

    // MARK: Scheduling

    /// Upcoming cues as delays from now, including the resume countdown beeps.
    private func upcoming() -> [(delay: TimeInterval, cue: Cue)] {
        guard let s = session, s.state == .running else { return [] }
        let n = now()
        var out: [(delay: TimeInterval, cue: Cue)] = []
        if let r = s.resumeCountdownRemaining(at: n) {
            for k in [3, 2, 1] {
                let delay = r - TimeInterval(k)
                if delay > -0.05 { out.append((delay, .countdownBeep(k))) }
            }
        }
        for event in s.cues where event.time > lastScheduleTime || (!firedStart && event.time >= lastScheduleTime) {
            guard let wall = s.wallTime(forScheduleTime: event.time) else { continue }
            out.append((wall - n, event.cue))
        }
        return out
    }

    private func rescheduleAudio() {
        guard let settings, session?.state == .running else { return }
        if settings.sound == .on {
            audio.schedule(upcoming(), boost: settings.volumeBoost)
        } else {
            audio.cancelScheduled()
        }
    }

    private func scheduleNotifications() {
        guard let settings else { return }
        let changes = upcoming().filter {
            switch $0.cue {
            case .runStart, .recoverStart, .finish: return true
            default: return false
            }
        }
        notifications.schedule(changes, audible: settings.sound != .on)
    }

    private func didEnterBackground() {
        isForeground = false
        if session?.state == .running { scheduleNotifications() }
    }

    private func willEnterForeground() {
        isForeground = true
        notifications.cancel()
        haptics.prepare()
        if session?.state == .running {
            rescheduleAudio()
            tick()
        }
    }

    // MARK: Live Activity

    private func activityState() -> RunActivityAttributes.ContentState? {
        guard let s = session, let snap = snapshot, let phase = snap.phase else { return nil }
        let n = now()
        let date = Date()
        let startDelay = (s.wallTime(forScheduleTime: phase.start) ?? n) - n
        let endDelay = (s.wallTime(forScheduleTime: phase.end) ?? n) - n
        let kind: RunActivityAttributes.ContentState.Kind
        switch phase.kind {
        case .ready: kind = .ready
        case .work: kind = .work
        case .recover: kind = .recover
        }
        return RunActivityAttributes.ContentState(
            kind: kind,
            step: phase.step ?? 1,
            totalSteps: phase.totalSteps,
            phaseStart: date.addingTimeInterval(startDelay),
            phaseEnd: date.addingTimeInterval(max(startDelay, endDelay)),
            isPaused: s.state == .paused,
            pausedRemaining: TimeFormat.displaySeconds(snap.remaining),
            nextLabel: PhaseCopy.next(after: phase, firstWork: s.schedule.intervals.first?.work)
        )
    }
}

/// Run-screen copy shared by the screens and the Live Activity.
enum PhaseCopy {
    static func name(_ kind: PhaseKind) -> String {
        switch kind {
        case .ready: return "Get ready"
        case .work: return "Run hard"
        case .recover: return "Recover"
        }
    }

    static func next(after phase: Phase, firstWork: Int?) -> String {
        if phase.kind == .ready {
            return "First: run hard " + TimeFormat.clock(firstWork ?? 0)
        }
        guard let next = phase.next else { return "Next: finish" }
        let what = next.kind == .work ? "run hard" : "recover"
        return "Next: \(what) " + TimeFormat.clock(Int(next.duration))
    }
}
