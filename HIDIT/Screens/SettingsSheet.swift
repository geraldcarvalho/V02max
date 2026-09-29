import SwiftUI
import HIDITCore

struct SettingsSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var run: RunController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .typeStyle(.display, uppercase: true)
                    .foregroundStyle(Tokens.Colors.ink)
                    .padding(.bottom, 12)
                    .accessibilityAddTraits(.isHeader)
                Card(radius: Layout.summaryCardRadius) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.space2) {
                        Text("Sound").typeStyle(.bodyMedium).foregroundStyle(Tokens.Colors.ink)
                        SegmentedControl(
                            options: [("On", SoundMode.on), ("Off", SoundMode.off), ("Voice only", SoundMode.voice)],
                            selection: $settings.sound,
                            accessibilityLabel: "Sound"
                        )
                    }
                    .padding(Tokens.Spacing.space3)
                    Hairline()
                    toggle("Haptics", $settings.haptics)
                    Hairline()
                    toggle("Volume boost", $settings.volumeBoost)
                    Hairline()
                    toggle("Countdown ticks", $settings.countdownTicks)
                    Hairline()
                    VStack(alignment: .leading, spacing: Tokens.Spacing.space2) {
                        Text("Countdown length").typeStyle(.bodyMedium).foregroundStyle(Tokens.Colors.ink)
                        SegmentedControl(
                            options: Schedule.allowedCountdowns.map { ($0 == 0 ? "Off" : "\($0) s", $0) },
                            selection: $settings.countdownLength,
                            accessibilityLabel: "Countdown length"
                        )
                    }
                    .padding(Tokens.Spacing.space3)
                }
                Text("Test cues").labelStyle().padding(.top, Tokens.Spacing.space3)
                HStack(spacing: Tokens.Spacing.space2) {
                    Button("Run") { run.test(.runStart(step: 1)) }.buttonStyle(.outlinePill)
                    Button("Recover") { run.test(.recoverStart(step: 1)) }.buttonStyle(.outlinePill)
                    Button("Finish") { run.test(.finish) }.buttonStyle(.outlinePill)
                }
                .padding(.top, Tokens.Spacing.space2)
            }
            .padding(.horizontal, Layout.margin)
            .padding(.top, 28)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Done") { dismiss() }
                .buttonStyle(.primary)
                .padding(.horizontal, Layout.margin)
                .padding(.bottom, Tokens.Spacing.space3)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Layout.sheetRadius)
        .presentationBackground {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Tokens.Colors.ground.opacity(0.78)
            }
        }
        .environment(\.colorScheme, .light)
    }

    private func toggle(_ title: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(title).typeStyle(.body).foregroundStyle(Tokens.Colors.ink)
        }
        .toggleStyle(AxisToggleStyle())
        .padding(.horizontal, Tokens.Spacing.space3)
    }
}
