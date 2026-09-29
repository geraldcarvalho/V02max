import SwiftUI
import HIDITCore

/// Work, recover, paused and the resume Ready countdown share this layout.
struct RunView: View {
    @EnvironmentObject private var run: RunController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flash = 0.0

    var body: some View {
        let snap = run.snapshot
        let phase = snap?.phase
        let kind = phase?.kind ?? .work
        let paused = snap?.state == .paused
        let resume = snap?.resumeCountdown
        let color = kind == .recover ? Tokens.Colors.recover : Tokens.Colors.work
        let timerText = resume.map { "\(TimeFormat.displaySeconds($0))" } ?? TimeFormat.clock(TimeFormat.displaySeconds(snap?.remaining ?? 0))
        let label = paused ? "Paused" : (resume != nil ? "Ready" : PhaseCopy.name(kind))
        let hotSecond = (snap?.isInLastSeconds ?? false) ? TimeFormat.displaySeconds(snap?.remaining ?? 0) : 0

        ScreenScaffold(background: paused ? Tokens.Colors.ground : Tokens.Colors.tint(color), scrolls: false) {
            HStack {
                Text(run.workoutName).labelStyle()
                Spacer()
                if let phase, let step = phase.step {
                    Text("Step \(step) of \(phase.totalSteps)").labelStyle()
                }
            }

            Spacer(minLength: 0)
            ZStack {
                ProgressRing(progress: snap?.progress ?? 0, color: color)
                VStack(spacing: 12) {
                    DiagonalArrow(direction: kind == .recover ? .downRight : .upRight, color: color)
                        .scaleEffect(40 / Layout.arrowSize)
                        .frame(width: 40, height: 40)
                    Numeral("\(Int(((snap?.progress ?? 0) * 100).rounded()))%", token: .percent.sized(34), color: color)
                    Text(label)
                        .typeStyle(.phase, uppercase: true)
                        .foregroundStyle(paused ? Tokens.Colors.muted : color)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .frame(maxWidth: 280, maxHeight: 280)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)

            Numeral(timerText, token: timerText.count > 4 ? .runTimerLong : .runTimer, color: color)
                .opacity(paused ? Layout.pausedTimerOpacity : 1)
                .keyframeAnimator(initialValue: 1.0, trigger: reduceMotion ? 0 : hotSecond) { view, scale in
                    view.scaleEffect(scale, anchor: .bottomLeading)
                } keyframes: { _ in
                    CubicKeyframe(hotSecond > 0 ? 1.04 : 1, duration: 0.15)
                    CubicKeyframe(1.0, duration: 0.3)
                }
                .accessibilityAddTraits(.updatesFrequently)

            if let phase {
                HStack(alignment: .firstTextBaseline) {
                    Text(PhaseCopy.next(after: phase, firstWork: nil))
                        .typeStyle(.smallSemibold)
                        .foregroundStyle(Tokens.Colors.ink)
                    Spacer()
                    Text("of").labelStyle()
                    Numeral(TimeFormat.clock(Int(phase.duration)), token: Tokens.Typography.numeralSm)
                }
                .padding(.top, Tokens.Spacing.space3)
                .accessibilityElement(children: .combine)
            }
        } actions: {
            Button(paused ? "Resume" : "Pause") {
                paused ? run.resume() : run.pause()
            }
            .buttonStyle(.primary)
            if paused {
                Button("End run") { run.stop() }.buttonStyle(.secondary)
            }
        }
        .overlay(Color.white.opacity(flash).ignoresSafeArea().allowsHitTesting(false))
        .animation(reduceMotion ? nil : .easeInOut(duration: kind == .recover ? 0.3 : Layout.phaseFade), value: kind)
        .animation(reduceMotion ? nil : .easeInOut(duration: Layout.phaseFade), value: paused)
        .onChange(of: kind) { _, newKind in
            // Brief brightness pulse when work starts; recover gets the slower fade above.
            guard newKind == .work, !reduceMotion else { return }
            flash = 0.25
            withAnimation(.easeOut(duration: 0.15)) { flash = 0 }
        }
    }
}
