import Foundation
import UserNotifications
import HIDITCore

/// Backup cues while the app is in the background: iOS does not play haptics there, so each upcoming
/// phase change is also posted as a local notification. With app sound on they are silent banners;
/// with sound off or voice only they use the default sound, which also vibrates the phone.
@MainActor
final class PhaseNotifications {
    private let center = UNUserNotificationCenter.current()
    private let prefix = "hidit.phase."

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// `changes` are delays in seconds from now with their cue.
    func schedule(_ changes: [(delay: TimeInterval, cue: Cue)], audible: Bool) {
        cancel()
        for (i, item) in changes.prefix(60).enumerated() where item.delay > 1 {
            guard let body = Self.text(for: item.cue) else { continue }
            let content = UNMutableNotificationContent()
            content.title = body.title
            content.body = body.body
            content.sound = audible ? .default : nil
            content.interruptionLevel = .active
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: item.delay, repeats: false)
            center.add(UNNotificationRequest(identifier: prefix + String(i), content: content, trigger: trigger))
        }
    }

    func cancel() {
        let ids = (0..<60).map { prefix + String($0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    private static func text(for cue: Cue) -> (title: String, body: String)? {
        switch cue {
        case .runStart(let step): return ("Run hard", "Step \(step)")
        case .recoverStart(let step): return ("Recover", "Step \(step)")
        case .finish: return ("Run finished", "Open HIDIT to see your stats")
        default: return nil
        }
    }
}
