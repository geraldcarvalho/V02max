import ActivityKit
import Foundation

/// Live Activity for a run: shown on the lock screen and in the Dynamic Island.
struct RunActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Kind: String, Codable, Hashable {
            case ready
            case work
            case recover
        }

        var kind: Kind
        var step: Int
        var totalSteps: Int
        /// Wall-clock window of the current phase, so `Text(timerInterval:)` counts down without updates.
        var phaseStart: Date
        var phaseEnd: Date
        var isPaused: Bool
        /// Remaining seconds shown while paused.
        var pausedRemaining: Int
        var nextLabel: String

        var phaseName: String {
            if isPaused { return "Paused" }
            switch kind {
            case .ready: return "Get ready"
            case .work: return "Run hard"
            case .recover: return "Recover"
            }
        }
    }

    var workoutName: String
}
