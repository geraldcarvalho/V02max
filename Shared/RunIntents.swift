import AppIntents
import Foundation

// Buttons on the Live Activity. LiveActivityIntent runs `perform()` in the app's process, so the
// widget extension only needs the type; the work happens in the app.

struct PauseRunIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause run"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await RunController.shared.pause()
        #endif
        return .result()
    }
}

struct ResumeRunIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume run"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await RunController.shared.resume()
        #endif
        return .result()
    }
}
