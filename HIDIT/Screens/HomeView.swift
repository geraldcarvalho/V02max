import SwiftUI
import HIDITCore

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    let onEdit: (Preset) -> Void
    let onSettings: () -> Void
    let onStart: () -> Void
    @State private var showPicker = false

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

            VStack(alignment: .leading, spacing: 4) {
                Text("Workout").labelStyle()
                VStack(spacing: 0) {
                    DashedLine()
                    HStack(spacing: 0) {
                        Button { showPicker = true } label: {
                            HStack(spacing: 14) {
                                Group {
                                    if settings.selectedPreset == .hidit { LadderGlyph() } else { Color.clear }
                                }
                                .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(settings.selectedPreset.name).typeStyle(.phase, uppercase: true).foregroundStyle(Tokens.Colors.ink)
                                    Text(settings.selectedPreset.detail).labelStyle()
                                }
                                Spacer(minLength: 8)
                                AxisIcon.chevron.image
                                    .rotationEffect(.degrees(90))
                                    .frame(width: 22, height: 22)
                                    .foregroundStyle(Tokens.Colors.ink)
                            }
                            .frame(maxWidth: .infinity, minHeight: Layout.rowMinHeight, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(settings.selectedPreset.name), \(settings.selectedPreset.detail). Change workout")
                        if let edit = editAction(for: settings.selectedPreset) {
                            Button(action: edit) {
                                AxisIcon.chevron.image
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(Tokens.Colors.muted)
                                    .frame(width: Layout.iconButton, height: Layout.iconButton)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit \(settings.selectedPreset.name)")
                        }
                    }
                    DashedLine()
                }
            }
            .padding(.top, 24)

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
        .sheet(isPresented: $showPicker) {
            WorkoutPickerSheet(onEdit: { preset in
                showPicker = false
                onEdit(preset)
            })
        }
    }

    private func editAction(for preset: Preset) -> (() -> Void)? {
        guard preset.isEditable else { return nil }
        return { onEdit(preset) }
    }
}

/// Light card that repeats the session total as a big numeral.
struct SummaryCard: View {
    let caption: String
    let total: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(caption)
                .typeStyle(.label, uppercase: true)
                .foregroundStyle(Tokens.Colors.muted)
            NumeralRow(text: total, token: .total, color: Tokens.Colors.ink)
        }
        .padding(Tokens.Spacing.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Colors.surface, in: RoundedRectangle(cornerRadius: Layout.summaryCardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Layout.summaryCardRadius, style: .continuous).strokeBorder(Tokens.Colors.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption). Total \(Numeral.spoken(total))")
    }
}

/// Bottom sheet listing every workout. Choosing one closes the sheet.
struct WorkoutPickerSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let onEdit: (Preset) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Workouts")
                    .typeStyle(.display, uppercase: true)
                    .foregroundStyle(Tokens.Colors.ink)
                    .padding(.bottom, 12)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(Preset.allCases.enumerated()), id: \.element) { item in
                    if item.offset > 0 { DashedLine() }
                    PresetRow(
                        preset: item.element,
                        selected: settings.selectedPreset == item.element,
                        onSelect: {
                            settings.selectedPreset = item.element
                            dismiss()
                        },
                        onEdit: item.element.isEditable ? { onEdit(item.element) } as (() -> Void)? : nil
                    )
                }
            }
            .padding(.horizontal, Layout.margin)
            .padding(.top, 28)
            .padding(.bottom, Tokens.Spacing.space5)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Layout.sheetRadius)
        .presentationBackground {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Tokens.Colors.ground.opacity(0.78)
            }
        }
    }
}
