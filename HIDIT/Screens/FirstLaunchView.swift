import SwiftUI

struct FirstLaunchView: View {
    let onDone: () -> Void

    var body: some View {
        ScreenScaffold(calm: true, scrolls: false) {
            Spacer(minLength: 0)
            LadderGlyph(barWidth: 7, heights: [44, 34, 24, 14], spacing: 5)
            Text("Interval timer")
                .typeStyle(.display, uppercase: true)
                .foregroundStyle(Tokens.Colors.ink)
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)
            Text("HIDIT and fixed presets for VO2 max training.")
                .typeStyle(.body)
                .foregroundStyle(Tokens.Colors.muted)
                .padding(.top, Tokens.Spacing.space2)
            HStack(alignment: .top, spacing: 12) {
                AxisIcon.info.image
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Tokens.Colors.muted)
                    .accessibilityHidden(true)
                Text("Check with a doctor before high-intensity training")
                    .typeStyle(.body)
                    .foregroundStyle(Tokens.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Tokens.Spacing.space3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.Colors.surface, in: RoundedRectangle(cornerRadius: Layout.summaryCardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Layout.summaryCardRadius, style: .continuous).strokeBorder(Tokens.Colors.hairline, lineWidth: 1))
            .padding(.top, 40)
            Spacer(minLength: 0)
        } actions: {
            Button("Got it", action: onDone).buttonStyle(.primary)
        }
    }
}
