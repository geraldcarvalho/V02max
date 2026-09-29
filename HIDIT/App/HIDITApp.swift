import SwiftUI

@main
struct HIDITApp: App {
    @StateObject private var settings = AppSettings()
    @ObservedObject private var run = RunController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(run)
                .preferredColorScheme(.light)
                .onAppear { run.settings = settings }
        }
    }
}
