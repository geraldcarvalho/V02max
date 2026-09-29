import SwiftUI
import HIDITCore

/// The pre-run countdown. Pause is not offered here: Cancel ends the run, Skip starts it now.
struct GetReadyView: View {
    @EnvironmentObject private var run: RunController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let snap = run.snapshot
        let seconds = TimeFormat.displaySeconds(snap?.remaining ?? 0)
        let firstWork = run.session?.schedule.intervals.first?.work ?? 0
        ScreenScaffold(calm: true, scrolls: false) {
            Text(run.workoutName).labelStyle()
            Spacer(minLength: 0)
            VStack(spacing: 12) {
                Text("Get ready").typeStyle(.phase, uppercase: true).foregroundStyle(Tokens.Colors.ink)
                Text("First: run hard " + TimeFormat.clock(firstWork)).labelStyle()
            }
            .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            NumeralRow(text: "\(seconds)", token: .countdown)
                .keyframeAnimator(initialValue: 1.0, trigger: reduceMotion ? 0 : seconds) { view, scale in
                    view.scaleEffect(scale, anchor: .bottomLeading)
                } keyframes: { _ in
                    CubicKeyframe(1.04, duration: 0.15)
                    CubicKeyframe(1.0, duration: 0.3)
                }
                .accessibilityLabel("Starting in \(seconds)")
        } actions: {
            Button("Skip") { run.skipCountdown() }.buttonStyle(.primary)
            Button("Cancel") { run.stop() }.buttonStyle(.quiet)
        }
    }
}
