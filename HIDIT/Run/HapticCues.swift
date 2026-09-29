import CoreHaptics
import UIKit
import HIDITCore

/// Haptic patterns for each cue. iOS only plays haptics while the app is in the foreground.
final class HapticCues {
    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private let impact = UIImpactFeedbackGenerator(style: .medium)

    func prepare() {
        guard supportsHaptics else { impact.prepare(); return }
        if engine == nil {
            engine = try? CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        }
        try? engine?.start()
    }

    func play(_ cue: Cue) {
        guard supportsHaptics, let engine else {
            fallback(cue)
            return
        }
        guard let events = events(for: cue), !events.isEmpty,
              let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? engine.start()
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    private func tap(_ time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time)
    }

    private func buzz(_ time: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time, duration: duration)
    }

    private func events(for cue: Cue) -> [CHHapticEvent]? {
        switch cue {
        case .runStart:
            // Two sharp taps.
            return [tap(0, intensity: 1, sharpness: 0.9), tap(0.11, intensity: 1, sharpness: 0.9)]
        case .recoverStart:
            // One long, gentle buzz.
            return [buzz(0, duration: 0.42, intensity: 0.55, sharpness: 0.15)]
        case .tickIntoRecover:
            return [tap(0, intensity: 0.6, sharpness: 0.7)]
        case .tickIntoRun:
            return [tap(0, intensity: 0.4, sharpness: 0.2)]
        case .countdownBeep:
            return [tap(0, intensity: 0.5, sharpness: 0.5)]
        case .countdownTick:
            return nil
        case .finish:
            // Strong triple pulse.
            return [
                buzz(0, duration: 0.09, intensity: 1, sharpness: 0.6),
                buzz(0.15, duration: 0.09, intensity: 1, sharpness: 0.6),
                buzz(0.3, duration: 0.16, intensity: 1, sharpness: 0.6),
            ]
        }
    }

    private func fallback(_ cue: Cue) {
        switch cue {
        case .runStart:
            impact.impactOccurred(intensity: 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) { self.impact.impactOccurred(intensity: 1) }
        case .recoverStart:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .tickIntoRecover, .countdownBeep:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .tickIntoRun:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
        case .countdownTick:
            break
        case .finish:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
