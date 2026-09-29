import Foundation

/// A sound, haptic or voice moment in a run.
public enum Cue: Equatable, Hashable, Sendable {
    /// Soft tick each second from 10 to 4 in the pre-run countdown.
    case countdownTick
    /// Rising beep at 3, 2 and 1 in the pre-run countdown or the resume countdown.
    case countdownBeep(Int)
    /// Work starts: two bright rising beeps, two sharp taps.
    case runStart(step: Int)
    /// Recover starts: one long soft falling tone, one long gentle buzz.
    case recoverStart(step: Int)
    /// Last 3 seconds of a work phase: short rising ticks, light taps.
    case tickIntoRecover(Int)
    /// Last 3 seconds of a recover phase: soft flat ticks, soft taps.
    case tickIntoRun(Int)
    /// Run complete: three-note ascending chime, strong triple pulse.
    case finish
}

public struct CueEvent: Equatable, Hashable, Sendable {
    /// Schedule time the cue plays at.
    public var time: TimeInterval
    public var cue: Cue
}

public struct CueOptions: Equatable, Sendable {
    /// The "Countdown ticks" setting: soft pre-run ticks and the in-run 3-2-1 ticks.
    public var ticks: Bool

    public init(ticks: Bool) {
        self.ticks = ticks
    }
}

public extension Schedule {
    /// Every cue of the run in time order.
    func cuePlan(_ options: CueOptions) -> [CueEvent] {
        var events: [CueEvent] = []
        for phase in phases {
            switch phase.kind {
            case .ready:
                let d = Int(phase.duration)
                for n in stride(from: d, through: 1, by: -1) {
                    let time = phase.end - TimeInterval(n)
                    if n <= 3 {
                        events.append(CueEvent(time: time, cue: .countdownBeep(n)))
                    } else if options.ticks && n <= 10 {
                        events.append(CueEvent(time: time, cue: .countdownTick))
                    }
                }
            case .work, .recover:
                let step = phase.step ?? 0
                events.append(CueEvent(time: phase.start, cue: phase.kind == .work ? .runStart(step: step) : .recoverStart(step: step)))
                if options.ticks && phase.duration > Schedule.tickThreshold {
                    for n in [3, 2, 1] {
                        let time = phase.end - TimeInterval(n)
                        events.append(CueEvent(time: time, cue: phase.kind == .work ? .tickIntoRecover(n) : .tickIntoRun(n)))
                    }
                }
            }
        }
        if !phases.isEmpty {
            events.append(CueEvent(time: totalDuration, cue: .finish))
        }
        return events.sorted { $0.time < $1.time }
    }
}

public extension Array where Element == CueEvent {
    /// Cues with `lower < time <= upper`; with `includeLower`, also those exactly at `lower`.
    func between(_ lower: TimeInterval, _ upper: TimeInterval, includeLower: Bool = false) -> [CueEvent] {
        filter { ($0.time > lower || (includeLower && $0.time == lower)) && $0.time <= upper }
    }
}
