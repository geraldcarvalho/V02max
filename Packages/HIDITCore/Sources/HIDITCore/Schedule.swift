import Foundation

public enum PhaseKind: String, Equatable, Hashable, Sendable, Codable {
    /// The pre-run "Get ready" countdown.
    case ready
    case work
    case recover
}

/// One timed segment of a run. Times are schedule time: seconds since the run started, excluding pauses.
public struct Phase: Equatable, Hashable, Sendable {
    public var kind: PhaseKind
    public var start: TimeInterval
    public var duration: TimeInterval
    /// 1-based step number; nil for the ready phase.
    public var step: Int?
    public var totalSteps: Int
    /// 1-based round; HIDIT repeats its ladder until the person stops.
    public var round: Int
    public var totalRounds: Int
    /// The phase that follows; nil when this is the last one.
    public var next: Next?

    public struct Next: Equatable, Hashable, Sendable {
        public var kind: PhaseKind
        public var duration: TimeInterval
    }

    public var end: TimeInterval { start + duration }
}

/// The full run, precomputed at start.
public struct Schedule: Equatable, Sendable {
    /// Phases of 20 seconds or less skip the 3-2-1 ticks.
    public static let tickThreshold: TimeInterval = 20
    public static let allowedCountdowns = [0, 5, 10, 15]
    /// HIDIT runs until volitional exhaustion. The schedule is precomputed, so it holds this many rounds
    /// (about two hours at the default ladder), after which the run finishes.
    public static let repeatingRounds = 10

    public let intervals: [Interval]
    public let phases: [Phase]
    public let countdown: Int
    public let rounds: Int

    public var totalDuration: TimeInterval { phases.last?.end ?? 0 }
    public var intervalDuration: TimeInterval { TimeInterval(intervals.totalSeconds) }
    public var hasCountdown: Bool { countdown > 0 }

    /// Builds the schedule: an optional ready countdown, then work and recover for every interval,
    /// repeated for `rounds` rounds.
    public init(intervals: [Interval], countdown: Int, rounds: Int = 1) {
        self.intervals = intervals
        self.countdown = max(0, countdown)
        let rounds = max(1, rounds)
        self.rounds = rounds
        var phases: [Phase] = []
        var t: TimeInterval = 0
        let total = intervals.count
        if countdown > 0, !intervals.isEmpty {
            phases.append(Phase(kind: .ready, start: 0, duration: TimeInterval(countdown), step: nil, totalSteps: total, round: 1, totalRounds: rounds, next: nil))
            t = TimeInterval(countdown)
        }
        for round in 1...rounds {
            for (i, interval) in intervals.enumerated() {
                phases.append(Phase(kind: .work, start: t, duration: TimeInterval(interval.work), step: i + 1, totalSteps: total, round: round, totalRounds: rounds, next: nil))
                t += TimeInterval(interval.work)
                phases.append(Phase(kind: .recover, start: t, duration: TimeInterval(interval.recover), step: i + 1, totalSteps: total, round: round, totalRounds: rounds, next: nil))
                t += TimeInterval(interval.recover)
            }
        }
        for i in phases.indices where i + 1 < phases.count {
            phases[i].next = Phase.Next(kind: phases[i + 1].kind, duration: phases[i + 1].duration)
        }
        self.phases = phases
    }

    /// Index of the phase running at schedule time `t`; nil once the run is over.
    public func phaseIndex(at t: TimeInterval) -> Int? {
        guard t < totalDuration else { return nil }
        // Phases are few (at most 41), so a linear scan is fine.
        return phases.lastIndex { $0.start <= t }
    }
}

/// What was done up to a moment in a run.
public struct RunStats: Equatable, Sendable {
    /// Recover phases fully completed.
    public var steps: Int
    public var workSeconds: Int
    public var recoverSeconds: Int
    public var longestWork: Int

    public var totalSeconds: Int { workSeconds + recoverSeconds }
}

public extension Schedule {
    /// Work, recover and completed steps between the end of the countdown and schedule time `t`.
    func stats(at t: TimeInterval) -> RunStats {
        var stats = RunStats(steps: 0, workSeconds: 0, recoverSeconds: 0, longestWork: 0)
        var work = 0.0, recover = 0.0, longest = 0.0
        for phase in phases where phase.kind != .ready {
            let done = min(phase.duration, max(0, t - phase.start))
            guard done > 0 else { continue }
            switch phase.kind {
            case .work:
                work += done
                longest = max(longest, done)
            case .recover:
                recover += done
                if done >= phase.duration { stats.steps += 1 }
            case .ready:
                break
            }
        }
        stats.workSeconds = Int(work.rounded())
        stats.recoverSeconds = Int(recover.rounded())
        stats.longestWork = Int(longest.rounded())
        return stats
    }
}
