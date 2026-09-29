import SwiftUI
import HIDITCore

/// Picks the screen from app state. There are no menus mid-run: the run screens replace everything.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var run: RunController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editing: Preset?
    @State private var showSettings = false

    private enum Screen: Equatable {
        case firstLaunch, home, builder(Preset), ready, run, finish
    }

    private var screen: Screen {
        if !settings.hasSeenHealthNote { return .firstLaunch }
        if run.summary != nil { return .finish }
        if run.isActive {
            return run.snapshot?.phase?.kind == .ready ? .ready : .run
        }
        if let editing { return .builder(editing) }
        return .home
    }

    var body: some View {
        Group {
            switch screen {
            case .firstLaunch:
                FirstLaunchView { settings.hasSeenHealthNote = true }
            case .home:
                HomeView(onEdit: { editing = $0; settings.selectedPreset = $0 }, onSettings: { showSettings = true }, onStart: start)
            case .builder(let preset):
                BuilderView(preset: preset, onBack: { editing = nil }, onStart: start)
            case .ready:
                GetReadyView()
            case .run:
                RunView()
            case .finish:
                FinishView { run.dismissSummary() }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: Layout.phaseFade), value: screen)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    private func start() {
        run.start()
    }
}

/// Full-screen layout: 20 pt side margins, scrolling content, actions pinned to the bottom.
struct ScreenScaffold<Content: View, Actions: View>: View {
    var calm = false
    var background: Color = Tokens.Colors.ground
    var scrolls = true
    @ViewBuilder var content: Content
    @ViewBuilder var actions: Actions

    var body: some View {
        ZStack {
            if calm { CalmBackground() } else { background.ignoresSafeArea() }
            Group {
                if scrolls {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) { content }
                            .padding(.horizontal, Layout.margin)
                            .padding(.top, Tokens.Spacing.space3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    VStack(alignment: .leading, spacing: 0) { content }
                        .padding(.horizontal, Layout.margin)
                        .padding(.top, Tokens.Spacing.space3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: Tokens.Spacing.space2 + 4) { actions }
                    .padding(.horizontal, Layout.margin)
                    .padding(.top, Tokens.Spacing.space3)
                    .padding(.bottom, Tokens.Spacing.space3)
            }
        }
    }
}
