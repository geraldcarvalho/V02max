import Foundation

/// One step of a workout: a work interval followed by a recover interval, in whole seconds.
public struct Interval: Equatable, Hashable, Sendable, Codable {
    public var work: Int
    public var recover: Int

    public init(work: Int, recover: Int) {
        self.work = work
        self.recover = recover
    }
}

/// How much work shrinks from one HIDIT step to the next.
public enum StepDown: Equatable, Hashable, Sendable, Codable {
    case seconds(Int)
    case percent(Int)

    public var value: Int {
        switch self {
        case .seconds(let v), .percent(let v): return v
        }
    }

    public var isPercent: Bool {
        if case .percent = self { return true }
        return false
    }
}

/// The result of building a HIDIT ladder.
public struct Ladder: Equatable, Sendable {
    public var intervals: [Interval]
    /// True when the ladder stopped before the requested number of steps because work would drop under the minimum.
    public var clipped: Bool
}

/// HIDIT: work and recovery shrink each step while recovery stays at exactly work x 2/3.
public struct HIDITConfig: Equatable, Hashable, Sendable, Codable {
    public static let minimumWork = 10
    public static let startWorkRange = 60...600
    public static let startWorkStep = 15
    public static let stepsRange = 2...10
    public static let secondsStepDownRange = 5...60
    public static let percentStepDownRange = 5...40
    public static let stepDownIncrement = 5
    public static let defaultSecondsStepDown = 30
    public static let defaultPercentStepDown = 15

    public var startWork: Int
    public var steps: Int
    public var stepDown: StepDown

    public static let `default` = HIDITConfig(startWork: 180, steps: 5, stepDown: .seconds(30))

    public init(startWork: Int, steps: Int, stepDown: StepDown) {
        self.startWork = startWork
        self.steps = steps
        self.stepDown = stepDown
    }

    /// Recovery is always work x 2/3, rounded to the nearest second.
    public static func recovery(forWork work: Int) -> Int {
        Int((Double(work) * 2.0 / 3.0).rounded())
    }

    /// Recovery for the first step, shown read-only in the builder.
    public var startRecovery: Int { Self.recovery(forWork: startWork) }

    /// Returns a copy with every value inside its allowed range.
    public func clamped() -> HIDITConfig {
        var c = self
        c.startWork = min(max(c.startWork, Self.startWorkRange.lowerBound), Self.startWorkRange.upperBound)
        c.steps = min(max(c.steps, Self.stepsRange.lowerBound), Self.stepsRange.upperBound)
        switch c.stepDown {
        case .seconds(let v):
            c.stepDown = .seconds(min(max(v, Self.secondsStepDownRange.lowerBound), Self.secondsStepDownRange.upperBound))
        case .percent(let v):
            c.stepDown = .percent(min(max(v, Self.percentStepDownRange.lowerBound), Self.percentStepDownRange.upperBound))
        }
        return c
    }

    /// Switches the step-down unit and resets it to that unit's default.
    public func withStepDownUnit(percent: Bool) -> HIDITConfig {
        var c = self
        c.stepDown = percent ? .percent(Self.defaultPercentStepDown) : .seconds(Self.defaultSecondsStepDown)
        return c
    }

    public func ladder() -> Ladder {
        var intervals: [Interval] = []
        var work = Double(startWork)
        for _ in 0..<steps {
            let rounded = Int(work.rounded())
            if rounded < Self.minimumWork { break }
            intervals.append(Interval(work: rounded, recover: Self.recovery(forWork: rounded)))
            switch stepDown {
            case .seconds(let s): work -= Double(s)
            case .percent(let p): work *= 1.0 - Double(p) / 100.0
            }
        }
        return Ladder(intervals: intervals, clipped: intervals.count < steps)
    }
}

/// A custom workout: the same work and recover repeated.
public struct CustomConfig: Equatable, Hashable, Sendable, Codable {
    public static let workRange = 10...600
    public static let recoverRange = 5...600
    public static let stepsRange = 1...20
    public static let timeIncrement = 5

    public var work: Int
    public var recover: Int
    public var steps: Int

    public static let `default` = CustomConfig(work: 45, recover: 30, steps: 6)

    public init(work: Int, recover: Int, steps: Int) {
        self.work = work
        self.recover = recover
        self.steps = steps
    }

    public func clamped() -> CustomConfig {
        var c = self
        c.work = min(max(c.work, Self.workRange.lowerBound), Self.workRange.upperBound)
        c.recover = min(max(c.recover, Self.recoverRange.lowerBound), Self.recoverRange.upperBound)
        c.steps = min(max(c.steps, Self.stepsRange.lowerBound), Self.stepsRange.upperBound)
        return c
    }

    public var intervals: [Interval] {
        Array(repeating: Interval(work: work, recover: recover), count: steps)
    }
}

/// The workouts on the home list, in display order.
public enum Preset: String, CaseIterable, Identifiable, Sendable, Codable {
    case hidit
    case norwegian4x4
    case thirtyThirty
    case tabata
    case custom

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .hidit: return "HIDIT"
        case .norwegian4x4: return "Norwegian 4x4"
        case .thirtyThirty: return "30/30"
        case .tabata: return "Tabata"
        case .custom: return "Custom"
        }
    }

    public var detail: String {
        switch self {
        case .hidit: return "Decreasing intervals, 3:2 ratio"
        case .norwegian4x4: return "4 steps, 4:00 work, 3:00 recover"
        case .thirtyThirty: return "10 steps, 30 s work, 30 s recover"
        case .tabata: return "8 steps, 20 s work, 10 s recover"
        case .custom: return "Set your own work and recover"
        }
    }

    public var isEditable: Bool { self == .hidit || self == .custom }

    public func intervals(hidit: HIDITConfig, custom: CustomConfig) -> [Interval] {
        switch self {
        case .hidit: return hidit.ladder().intervals
        case .norwegian4x4: return Array(repeating: Interval(work: 240, recover: 180), count: 4)
        case .thirtyThirty: return Array(repeating: Interval(work: 30, recover: 30), count: 10)
        case .tabata: return Array(repeating: Interval(work: 20, recover: 10), count: 8)
        case .custom: return custom.intervals
        }
    }
}

public extension Array where Element == Interval {
    var totalSeconds: Int { reduce(0) { $0 + $1.work + $1.recover } }
    var workSeconds: Int { reduce(0) { $0 + $1.work } }
    var recoverSeconds: Int { reduce(0) { $0 + $1.recover } }
    var longestWork: Int { map(\.work).max() ?? 0 }
}
