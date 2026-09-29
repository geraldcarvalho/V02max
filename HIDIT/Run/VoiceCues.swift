import AVFoundation
import HIDITCore

/// Spoken phase names for the "Voice only" sound setting.
final class VoiceCues {
    private let synth = AVSpeechSynthesizer()

    func speak(_ cue: Cue) {
        guard let text = Self.phrase(for: cue) else { return }
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    static func phrase(for cue: Cue) -> String? {
        switch cue {
        case .runStart(let step): return "Run. Step \(step)"
        case .recoverStart: return "Recover"
        case .finish: return "Run finished"
        default: return nil
        }
    }
}
