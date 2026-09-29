import SwiftUI
import HIDITCore

struct FinishView: View {
    @EnvironmentObject private var run: RunController
    let onDone: () -> Void

    var body: some View {
        let s = run.summary
        ScreenScaffold(calm: true, scrolls: false) {
            Text(s?.workoutName ?? "").labelStyle()
            Text("Run finished")
                .typeStyle(.phase, uppercase: true)
                .foregroundStyle(Tokens.Colors.ink)
                .padding(.top, 96)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)], alignment: .leading, spacing: 28) {
                stat("Steps completed", s?.totalSteps.map { "\(s?.stepsCompleted ?? 0)/\($0)" } ?? "\(s?.stepsCompleted ?? 0)", Tokens.Colors.muted)
                stat("Longest work", TimeFormat.clock(s?.longestWork ?? 0), Tokens.Colors.muted)
                stat("Work time", TimeFormat.clock(s?.workSeconds ?? 0), Tokens.Colors.work)
                stat("Recover time", TimeFormat.clock(s?.recoverSeconds ?? 0), Tokens.Colors.recover)
            }
            .padding(.top, 48)
            Spacer(minLength: 0)
            NumeralRow(text: TimeFormat.clock(s?.totalSeconds ?? 0), token: .total)
                .accessibilityLabel("Total time \(Numeral.spoken(TimeFormat.clock(s?.totalSeconds ?? 0)))")
        } actions: {
            Button("Done", action: onDone).buttonStyle(.primary)
        }
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).typeStyle(.body).foregroundStyle(Tokens.Colors.ink)
            Numeral(value, token: .stat, color: color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value.contains(":") ? Numeral.spoken(value) : value.replacingOccurrences(of: "/", with: " of "))
    }
}
