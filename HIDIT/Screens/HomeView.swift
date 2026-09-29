import SwiftUI
import HIDITCore

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    let onEdit: (Preset) -> Void
    let onSettings: () -> Void
    let onStart: () -> Void

    var body: some View {
        let intervals = settings.intervals
        ScreenScaffold(calm: true) {
            HStack(alignment: .top, spacing: Tokens.Spacing.space3) {
                (Text("Hi, your next session is ") + Text(settings.selectedPreset.name).font(TypeToken.bodySemibold.font) + Text("."))
                    .typeStyle(.body)
                    .foregroundStyle(Tokens.Colors.ink)
                    .frame(maxWidth: 220, alignment: .leading)
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Date.now, format: .dateTime.weekday(.wide))
                        .typeStyle(.weekday, uppercase: true)
                        .foregroundStyle(Tokens.Colors.ink)
                    Text(Date.now, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        .labelStyle()
                }
            }

            IconButton(icon: .sliders, label: "Settings", action: onSettings)
                .padding(.top, Tokens.Spacing.space4)

            VStack(spacing: 0) {
                ForEach(Array(Preset.allCases.enumerated()), id: \.element) { item in
                    if item.offset > 0 { DashedLine() }
                    PresetRow(
                        preset: item.element,
                        selected: settings.selectedPreset == item.element,
                        onSelect: { settings.selectedPreset = item.element },
                        onEdit: editAction(for: item.element)
                    )
                }
            }
            .padding(.top, 24)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Workouts")

            SummaryCard(
                caption: "\(settings.selectedPreset.name), \(intervals.count) steps of intervals",
                total: TimeFormat.clock(intervals.totalSeconds)
            )
            .padding(.top, Tokens.Spacing.space3)
        } actions: {
            Button("Start", action: onStart)
                .buttonStyle(.primary)
                .disabled(intervals.isEmpty)
        }
    }

    private func editAction(for preset: Preset) -> (() -> Void)? {
        guard preset.isEditable else { return nil }
        return { onEdit(preset) }
    }
}

/// Black card that repeats the session total as a big numeral.
struct SummaryCard: View {
    let caption: String
    let total: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(caption)
                .typeStyle(.label, uppercase: true)
                .foregroundStyle(Tokens.Colors.onInkMuted)
            NumeralRow(text: total, token: .total, color: Tokens.Colors.onInk)
        }
        .padding(Tokens.Spacing.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Colors.ink, in: RoundedRectangle(cornerRadius: Layout.summaryCardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption). Total \(Numeral.spoken(total))")
    }
}
