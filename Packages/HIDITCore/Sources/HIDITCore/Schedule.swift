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

    public let intervals: [Interval]
    public let phases: [Phase]
    public let countdown: Int

    public var totalDuration: TimeInterval { phases.last?.end ?? 0 }
    public var intervalDuration: TimeInterval { TimeInterval(intervals.totalSeconds) }
    public var hasCountdown: Bool { countdown > 0 }

    /// Builds the schedule: an optional ready countdown, then work and recover for every interval.
    public init(intervals: [Interval], countdown: Int) {
        self.intervals = intervals
        self.countdown = max(0, countdown)
        var phases: [Phase] = []
        var t: TimeInterval = 0
        let total = intervals.count
        if countdown > 0, !intervals.isEmpty {
            phases.append(Phase(kind: .ready, start: 0, duration: TimeInterval(countdown), step: nil, totalSteps: total, next: nil))
            t = TimeInterval(countdown)
        }
        for (i, interval) in intervals.enumerated() {
            phases.append(Phase(kind: .work, start: t, duration: TimeInterval(interval.work), step: i + 1, totalSteps: total, next: nil))
            t += TimeInterval(interval.work)
            phases.append(Phase(kind: .recover, start: t, duration: TimeInterval(interval.recover), step: i + 1, totalSteps: total, next: nil))
            t += TimeInterval(interval.recover)
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
