import ActivityKit
import Foundation

/// Starts, updates and ends the run's Live Activity.
@MainActor
final class LiveActivityManager {
    private var activity: Activity<RunActivityAttributes>?

    func start(workoutName: String, state: RunActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()
        activity = try? Activity.request(
            attributes: RunActivityAttributes(workoutName: workoutName),
            content: ActivityContent(state: state, staleDate: state.phaseEnd.addingTimeInterval(60)),
            pushType: nil
        )
    }

    func update(_ state: RunActivityAttributes.ContentState) {
        guard let activity else { return }
        let stale = state.isPaused ? nil : state.phaseEnd.addingTimeInterval(60)
        Task { await activity.update(ActivityContent(state: state, staleDate: stale)) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
