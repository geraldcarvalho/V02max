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

/// HIDIT: a fixed ladder of work intervals that gets shorter each step. Recovery is always work x 2/3.
///
/// The default ladder is 3:00, 2:00, 1:00, 0:45 and 0:30 of work with recovery 2:00, 1:20, 0:40, 0:30
/// and 0:20 (12:05 in total). The last step is the loop.
public struct HIDITConfig: Equatable, Hashable, Sendable, Codable {
    public static let workRange = 10...600
    public static let workIncrement = 5
    public static let stepsRange = 2...10
    public static let defaultWorks = [180, 120, 60, 45, 30]
    /// Shrink applied to the last step's work when a new step is added.
    public static let addedStepDrop = 15

    /// Work seconds for each step, in order.
    public var works: [Int]

    public static let `default` = HIDITConfig(works: defaultWorks)

    public init(works: [Int]) {
        self.works = works
    }

    /// Recovery is always work x 2/3, rounded to the nearest second.
    public static func recovery(forWork work: Int) -> Int {
        Int((Double(work) * 2.0 / 3.0).rounded())
    }

    public var intervals: [Interval] {
        works.map { Interval(work: $0, recover: Self.recovery(forWork: $0)) }
    }

    /// Returns a copy with the step count and every work time inside its allowed range.
    public func clamped() -> HIDITConfig {
        var w = works.prefix(Self.stepsRange.upperBound).map { min(max($0, Self.workRange.lowerBound), Self.workRange.upperBound) }
        while w.count < Self.stepsRange.lowerBound { w.append(max(Self.workRange.lowerBound, (w.last ?? 60) - Self.addedStepDrop)) }
        return HIDITConfig(works: w)
    }

    public func addingStep() -> HIDITConfig {
        guard works.count < Self.stepsRange.upperBound else { return self }
        var c = self
        c.works.append(max(Self.workRange.lowerBound, (works.last ?? 60) - Self.addedStepDrop))
        return c
    }

    public func removingLastStep() -> HIDITConfig {
        guard works.count > Self.stepsRange.lowerBound else { return self }
        var c = self
        c.works.removeLast()
        return c
    }

    /// Changes one step's work by `delta` seconds, kept in range.
    public func adjustingWork(at index: Int, by delta: Int) -> HIDITConfig {
        guard works.indices.contains(index) else { return self }
        var c = self
        c.works[index] = min(max(works[index] + delta, Self.workRange.lowerBound), Self.workRange.upperBound)
        return c
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
        case .hidit: return hidit.intervals
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
