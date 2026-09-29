import SwiftUI
import HIDITCore

/// Flat surface card with a hairline border.
struct Card<Content: View>: View {
    var radius: CGFloat = Tokens.Radius.radiusCard
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Tokens.Colors.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Tokens.Colors.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// 1 pt hairline between rows of a card.
struct Hairline: View {
    var body: some View {
        Rectangle().fill(Tokens.Colors.hairline).frame(height: 1)
    }
}

/// Dashed divider for flat lists.
struct DashedLine: View {
    var vertical = false

    var body: some View {
        DashShape(vertical: vertical)
            .stroke(Tokens.Colors.dash, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
    }

    struct DashShape: Shape {
        let vertical: Bool
        func path(in rect: CGRect) -> Path {
            var p = Path()
            if vertical {
                p.move(to: CGPoint(x: rect.midX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            } else {
                p.move(to: CGPoint(x: rect.minX, y: rect.midY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
            return p
        }
    }
}

/// Four shrinking bars: the HIDIT mark.
struct LadderGlyph: View {
    var barWidth: CGFloat = 4
    var heights: [CGFloat] = [26, 20, 14, 8]
    var spacing: CGFloat = 3

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(heights.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                    .fill(Tokens.Colors.work)
                    .frame(width: barWidth, height: heights[i])
            }
        }
        .accessibilityHidden(true)
    }
}

/// One workout on the home list.
struct PresetRow: View {
    let preset: Preset
    let selected: Bool
    let onSelect: () -> Void
    let onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    Group {
                        if preset == .hidit { LadderGlyph() } else { Color.clear }
                    }
                    .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name).typeStyle(.phase, uppercase: true).foregroundStyle(Tokens.Colors.ink)
                        Text(preset.detail).labelStyle()
                    }
                    Spacer(minLength: 8)
                    AxisIcon.check.image
                        .frame(width: 22, height: 22)
                        .foregroundStyle(Tokens.Colors.ink)
                        .opacity(selected ? 1 : 0)
                }
                .frame(maxWidth: .infinity, minHeight: Layout.rowMinHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(preset.name), \(preset.detail)")
            .accessibilityAddTraits(selected ? [.isSelected] : [])

            if let onEdit {
                Button(action: onEdit) {
                    AxisIcon.chevron.image
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Tokens.Colors.muted)
                        .frame(width: Layout.iconButton, height: Layout.iconButton)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(preset.name)")
            }
        }
    }
}

/// A labelled value with minus and plus buttons.
struct StepperRow: View {
    let title: String
    var caption: String? = nil
    let value: String
    let accessibilityValue: String
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack(spacing: Tokens.Spacing.space2) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).typeStyle(.bodyMedium).foregroundStyle(Tokens.Colors.ink)
                if let caption { Text(caption).labelStyle() }
            }
            Spacer(minLength: 0)
            StepButton(symbol: "minus", label: "Decrease \(title)", action: decrement)
            Numeral(value, token: .value)
                .frame(minWidth: 72)
            StepButton(symbol: "plus", label: "Increase \(title)", action: increment)
        }
        .padding(.horizontal, Tokens.Spacing.space3)
        .frame(minHeight: Layout.fieldRowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    private struct StepButton: View {
        let symbol: String
        let label: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack {
                    Rectangle().fill(Tokens.Colors.muted).frame(width: 14, height: 1.5)
                    if symbol == "plus" {
                        Rectangle().fill(Tokens.Colors.muted).frame(width: 1.5, height: 14)
                    }
                }
                .frame(width: Layout.stepperButton, height: Layout.stepperButton)
                .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.radiusButton, style: .continuous).strokeBorder(Tokens.Colors.hairline, lineWidth: 1))
                .contentShape(Rectangle())
                .frame(width: Layout.iconButton, height: Layout.iconButton)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(label)
        }
    }
}

/// A row of mutually exclusive options.
struct SegmentedControl<Value: Hashable>: View {
    let options: [(label: String, value: Value)]
    @Binding var selection: Value
    let accessibilityLabel: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let on = option.value == selection
                Button { selection = option.value } label: {
                    Text(option.label)
                        .typeStyle(on ? .smallSemibold : .small)
                        .foregroundStyle(on ? Tokens.Colors.ink : Tokens.Colors.muted)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(on ? Tokens.Colors.hairline : .clear, in: RoundedRectangle(cornerRadius: Layout.segmentInnerRadius, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
        .padding(3)
        .overlay(RoundedRectangle(cornerRadius: Layout.segmentRadius, style: .continuous).strokeBorder(Tokens.Colors.hairline, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Switch in the Axis look: hairline track, work-colored when on.
struct AxisToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack {
                configuration.label
                Spacer()
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule().fill(configuration.isOn ? Tokens.Colors.work : .clear)
                    Capsule().strokeBorder(Tokens.Colors.hairline, lineWidth: 1)
                    Circle()
                        .fill(configuration.isOn ? Tokens.Colors.ground : Tokens.Colors.muted)
                        .frame(width: 24, height: 24)
                        .padding(3)
                }
                .frame(width: 52, height: 32)
                .animation(.easeOut(duration: 0.15), value: configuration.isOn)
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

/// Thin progress line with an end dot. Work fills forward; recover drains backward.
struct ProgressLine: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let x = geo.size.width * min(1, max(0, progress))
            ZStack(alignment: .leading) {
                Rectangle().fill(Tokens.Colors.dash).frame(height: 1)
                Rectangle().fill(color).frame(width: x, height: 2)
                Circle().fill(color).frame(width: 12, height: 12).offset(x: x - 6)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}

/// Work and recover bars per step, with dashed guides, step numbers and a legend.
struct LadderPreview: View {
    let intervals: [Interval]

    var body: some View {
        let maxWork = CGFloat(max(1, intervals.longestWork))
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(intervals.indices, id: \.self) { i in
                    HStack(alignment: .bottom, spacing: 0) {
                        DashedLine(vertical: true)
                        HStack(alignment: .bottom, spacing: 3) {
                            bar(Tokens.Colors.work, CGFloat(intervals[i].work) / maxWork)
                            bar(Tokens.Colors.recover, CGFloat(intervals[i].recover) / maxWork)
                        }
                        .padding(.leading, 6)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: Layout.ladderPreviewHeight)
            HStack(spacing: 0) {
                ForEach(intervals.indices, id: \.self) { i in
                    Text("\(i + 1)").typeStyle(Tokens.Typography.numeralSm.sized(11)).foregroundStyle(Tokens.Colors.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: Tokens.Spacing.space3) {
                legend(Tokens.Colors.work, "Work")
                legend(Tokens.Colors.recover, "Recover")
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ladder preview")
        .accessibilityValue(intervals.enumerated().map { "Step \($0.offset + 1): work \(Numeral.spoken(TimeFormat.clock($0.element.work))), recover \(Numeral.spoken(TimeFormat.clock($0.element.recover)))" }.joined(separator: ". "))
    }

    private func bar(_ color: Color, _ fraction: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 12, height: max(4, Layout.ladderPreviewHeight * fraction))
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(color).frame(width: 10, height: 10)
            Text(text).labelStyle()
        }
    }
}

/// The signal-to-ember gradient, behind calm screens.
struct CalmBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Tokens.Colors.ground
                Circle()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: Tokens.Colors.signal, location: 0),
                            .init(color: Tokens.Colors.ember, location: 0.58),
                            .init(color: Tokens.Colors.ground.opacity(0), location: 0.74),
                        ],
                        center: UnitPoint(x: 0.45, y: 0.45), startRadius: 0, endRadius: 200))
                    .frame(width: 400, height: 400)
                    .blur(radius: 10)
                    .offset(x: -170, y: geo.size.height - 280)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// One thin progress ring, starting at 12 o'clock. Work fills clockwise; recover drains back.
struct ProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            let r = d / 2 - 6
            let p = min(1, max(0, progress))
            ZStack {
                Circle()
                    .stroke(Tokens.Colors.hairline, lineWidth: 1)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .trim(from: 0, to: p)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: r * 2, height: r * 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
