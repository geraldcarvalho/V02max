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
        let intervals = isHIDIT ? settings.hidit.intervals : settings.custom.intervals
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
            title: "Steps",
            value: "\(h.works.count)",
            accessibilityValue: "\(h.works.count)",
            decrement: { settings.hidit = settings.hidit.removingLastStep() },
            increment: { settings.hidit = settings.hidit.addingStep() }
        )
        ForEach(h.works.indices, id: \.self) { i in
            Hairline()
            StepperRow(
                title: "Step \(i + 1)",
                caption: "Recover " + TimeFormat.clock(HIDITConfig.recovery(forWork: h.works[i])),
                value: TimeFormat.clock(h.works[i]),
                accessibilityValue: "work \(Numeral.spoken(TimeFormat.clock(h.works[i]))), recover \(Numeral.spoken(TimeFormat.clock(HIDITConfig.recovery(forWork: h.works[i]))))",
                decrement: { settings.hidit = settings.hidit.adjustingWork(at: i, by: -HIDITConfig.workIncrement) },
                increment: { settings.hidit = settings.hidit.adjustingWork(at: i, by: HIDITConfig.workIncrement) }
            )
        }
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

    private func updateCustom(_ change: (inout CustomConfig) -> Void) {
        var c = settings.custom
        change(&c)
        settings.custom = c.clamped()
    }
}
