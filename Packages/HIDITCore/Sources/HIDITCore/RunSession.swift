import Foundation

/// The state of one run, driven by a monotonic clock.
///
/// Every method takes `now`, a monotonic time in seconds (for example from `ContinuousClock`). Elapsed
/// time is derived from the anchor, never by counting ticks, so the timer cannot drift however often
/// or rarely it is read.
public struct RunSession: Equatable, Sendable {
    public static let resumeCountdown: TimeInterval = 3

    public enum State: Equatable, Sendable {
        case running
        case paused
        case finished
        case cancelled
    }

    public let schedule: Schedule
    public let cues: [CueEvent]
    public private(set) var state: State

    /// Schedule time reached at `anchor`.
    private var accumulated: TimeInterval
    /// Monotonic time at which the schedule clock (re)starts from `accumulated`; nil while paused or ended.
    /// After Resume it lies 3 seconds in the future, which holds the clock during the Ready countdown.
    private var anchor: TimeInterval?

    public init(schedule: Schedule, options: CueOptions, startedAt now: TimeInterval) {
        self.schedule = schedule
        self.cues = schedule.cuePlan(options)
        self.state = schedule.phases.isEmpty ? .finished : .running
        self.accumulated = 0
        self.anchor = schedule.phases.isEmpty ? nil : now
    }

    /// Seconds of the schedule elapsed at `now`, excluding pauses and resume countdowns.
    public func scheduleTime(at now: TimeInterval) -> TimeInterval {
        guard let anchor else { return accumulated }
        return min(schedule.totalDuration, accumulated + max(0, now - anchor))
    }

    /// Seconds left in the resume countdown, or nil when none is running.
    public func resumeCountdownRemaining(at now: TimeInterval) -> TimeInterval? {
        guard state == .running, let anchor, anchor > now else { return nil }
        return anchor - now
    }

    /// The monotonic time a schedule time will be reached, if the run keeps going; nil while paused.
    public func wallTime(forScheduleTime t: TimeInterval) -> TimeInterval? {
        guard state == .running, let anchor else { return nil }
        return anchor + (t - accumulated)
    }

    /// Marks the run finished once its schedule has run out. Returns true on that transition.
    @discardableResult
    public mutating func update(at now: TimeInterval) -> Bool {
        guard state == .running, scheduleTime(at: now) >= schedule.totalDuration else { return false }
        accumulated = schedule.totalDuration
        anchor = nil
        state = .finished
        return true
    }

    /// Pausing during the pre-run countdown cancels the run. Pausing mid-run freezes the clock.
    public mutating func pause(at now: TimeInterval) {
        guard state == .running else { return }
        let t = scheduleTime(at: now)
        if let i = schedule.phaseIndex(at: t), schedule.phases[i].kind == .ready {
            cancel()
            return
        }
        accumulated = t
        anchor = nil
        state = .paused
    }

    /// Resume gives a fresh 3-second Ready countdown before the clock runs again.
    public mutating func resume(at now: TimeInterval) {
        guard state == .paused else { return }
        anchor = now + Self.resumeCountdown
        state = .running
    }

    /// Skip jumps to the end of the pre-run countdown.
    public mutating func skipCountdown(at now: TimeInterval) {
        guard state == .running else { return }
        let t = scheduleTime(at: now)
        guard let i = schedule.phaseIndex(at: t), schedule.phases[i].kind == .ready else { return }
        accumulated = schedule.phases[i].end
        anchor = now
    }

    public mutating func cancel() {
        anchor = nil
        state = .cancelled
    }

    public func snapshot(at now: TimeInterval) -> Snapshot {
        let t = scheduleTime(at: now)
        let index = schedule.phaseIndex(at: t)
        let phase = index.map { schedule.phases[$0] }
        let remaining = phase.map { max(0, $0.end - t) } ?? 0
        var fraction: Double = 0
        if let phase, phase.duration > 0 {
            let done = min(1, max(0, (t - phase.start) / phase.duration))
            // Work fills forward; recover drains backward.
            fraction = phase.kind == .recover ? 1 - done : done
        }
        let finished = state == .finished || (state == .running && index == nil)
        return Snapshot(
            state: finished ? .finished : state,
            scheduleTime: t,
            phaseIndex: index,
            phase: phase,
            remaining: remaining,
            progress: fraction,
            resumeCountdown: resumeCountdownRemaining(at: now)
        )
    }

    public struct Snapshot: Equatable, Sendable {
        public var state: State
        public var scheduleTime: TimeInterval
        public var phaseIndex: Int?
        public var phase: Phase?
        public var remaining: TimeInterval
        /// 0...1. Work fills forward from 0; recover drains from 1.
        public var progress: Double
        public var resumeCountdown: TimeInterval?

        public var isInLastSeconds: Bool {
            guard let phase, phase.kind != .ready, resumeCountdown == nil, state == .running else { return false }
            return phase.duration > Schedule.tickThreshold && remaining <= 3 && remaining > 0
        }
    }
}
