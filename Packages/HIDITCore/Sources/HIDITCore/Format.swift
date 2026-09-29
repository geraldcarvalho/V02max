import Foundation

public enum TimeFormat {
    /// Formats seconds as m:ss, for example 3:00, 16:40, 0:45.
    public static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return "\(s / 60):" + String(format: "%02d", s % 60)
    }

    /// Whole seconds still showing for a remaining duration: 2.1 s shows as 3, 0.0 s as 0.
    public static func displaySeconds(_ remaining: TimeInterval) -> Int {
        max(0, Int(remaining.rounded(.up)))
    }
}
