import SwiftUI
import HIDITCore

/// Editor for HIDIT (start work, steps, step-down; recovery read-only) and for Custom.
struct BuilderView: View {
    @EnvironmentObject private var settings: AppSettings
    let preset: Preset
    let onBack: () -> Void
    let onStart: () -> Void

    var body: some View {
        let isHIDIT = preset == .hidit
        let ladder = settings.hidit.ladder()
        let intervals = isHIDIT ? ladder.intervals : settings.custom.intervals
        ScreenScaffold {
            IconButton(icon: .back, label: "Back to workouts", action: onBack)
                .padding(.bottom, Tokens.Spacing.space2)
            Text(isHIDIT ? "HIDIT builder" : "Custom workout")
                .typeStyle(.display, uppercase: true)
                .foregroundStyle(Tokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)

            Card {
                if isHIDIT { hiditFields } else { customFields }
            }
            .padding(.top, Tokens.Spacing.space3)

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Preview").typeStyle(.smallSemibold).foregroundStyle(Tokens.Colors.ink)
                        Spacer()
                        Text("Total").labelStyle()
                        Numeral(TimeFormat.clock(intervals.totalSeconds), token: .value)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total \(Numeral.spoken(TimeFormat.clock(intervals.totalSeconds)))")
                    LadderPreview(intervals: intervals)
                    if isHIDIT && ladder.clipped {
                        Text("Work would drop under 0:10, so the ladder stops at step \(intervals.count)")
                            .typeStyle(.label, uppercase: true)
                            .foregroundStyle(Tokens.Colors.work)
                    }
                }
                .padding(EdgeInsets(top: 14, leading: 16, bottom: 12, trailing: 16))
            }
            .padding(.top, Tokens.Spacing.space3)
        } actions: {
            Button("Start", action: onStart)
                .buttonStyle(.primary)
                .disabled(intervals.isEmpty)
        }
    }

    @ViewBuilder private var hiditFields: some View {
        let h = settings.hidit
        StepperRow(
            title: "Start work",
            value: TimeFormat.clock(h.startWork),
            accessibilityValue: Numeral.spoken(TimeFormat.clock(h.startWork)),
            decrement: { updateHIDIT { $0.startWork -= HIDITConfig.startWorkStep } },
            increment: { updateHIDIT { $0.startWork += HIDITConfig.startWorkStep } }
        )
        Hairline()
        StepperRow(
            title: "Steps",
            value: "\(h.steps)",
            accessibilityValue: "\(h.steps)",
            decrement: { updateHIDIT { $0.steps -= 1 } },
            increment: { updateHIDIT { $0.steps += 1 } }
        )
        Hairline()
        VStack(spacing: 4) {
            StepperRow(
                title: "Step-down",
                value: h.stepDown.isPercent ? "\(h.stepDown.value)%" : "\(h.stepDown.value) s",
                accessibilityValue: h.stepDown.isPercent ? "\(h.stepDown.value) percent" : "\(h.stepDown.value) seconds",
                decrement: { updateHIDIT { $0.stepDown = Self.adjust($0.stepDown, by: -HIDITConfig.stepDownIncrement) } },
                increment: { updateHIDIT { $0.stepDown = Self.adjust($0.stepDown, by: HIDITConfig.stepDownIncrement) } }
            )
            SegmentedControl(
                options: [("Seconds", false), ("Percent", true)],
                selection: Binding(
                    get: { settings.hidit.stepDown.isPercent },
                    set: { percent in
                        guard percent != settings.hidit.stepDown.isPercent else { return }
                        settings.hidit = settings.hidit.withStepDownUnit(percent: percent)
                    }
                ),
                accessibilityLabel: "Step-down unit"
            )
            .padding(.horizontal, Tokens.Spacing.space3)
            .padding(.bottom, 12)
        }
        Hairline()
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Recovery").typeStyle(.bodyMedium).foregroundStyle(Tokens.Colors.ink)
                Text("Work x 2/3, set automatically").labelStyle()
            }
            Spacer(minLength: 0)
            AxisIcon.lock.image
                .frame(width: 16, height: 16)
                .foregroundStyle(Tokens.Colors.muted)
            Numeral(TimeFormat.clock(h.startRecovery), token: .value, color: Tokens.Colors.recover)
        }
        .padding(.horizontal, Tokens.Spacing.space3)
        .frame(minHeight: Layout.fieldRowHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recovery, read only, work times 2 thirds")
        .accessibilityValue(Numeral.spoken(TimeFormat.clock(h.startRecovery)))
    }

    @ViewBuilder private var customFields: some View {
        let c = settings.custom
        StepperRow(
            title: "Work",
            value: TimeFormat.clock(c.work),
            accessibilityValue: Numeral.spoken(TimeFormat.clock(c.work)),
            decrement: { updateCustom { $0.work -= CustomConfig.timeIncrement } },
            increment: { updateCustom { $0.work += CustomConfig.timeIncrement } }
        )
        Hairline()
        StepperRow(
            title: "Recover",
            value: TimeFormat.clock(c.recover),
            accessibilityValue: Numeral.spoken(TimeFormat.clock(c.recover)),
            decrement: { updateCustom { $0.recover -= CustomConfig.timeIncrement } },
            increment: { updateCustom { $0.recover += CustomConfig.timeIncrement } }
        )
        Hairline()
        StepperRow(
            title: "Steps",
            value: "\(c.steps)",
            accessibilityValue: "\(c.steps)",
            decrement: { updateCustom { $0.steps -= 1 } },
            increment: { updateCustom { $0.steps += 1 } }
        )
    }

    private func updateHIDIT(_ change: (inout HIDITConfig) -> Void) {
        var h = settings.hidit
        change(&h)
        settings.hidit = h.clamped()
    }

    private func updateCustom(_ change: (inout CustomConfig) -> Void) {
        var c = settings.custom
        change(&c)
        settings.custom = c.clamped()
    }

    private static func adjust(_ stepDown: StepDown, by delta: Int) -> StepDown {
        switch stepDown {
        case .seconds(let v): return .seconds(v + delta)
        case .percent(let v): return .percent(v + delta)
        }
    }
}
