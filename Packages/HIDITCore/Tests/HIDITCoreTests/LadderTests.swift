import XCTest
@testable import HIDITCore

final class LadderTests: XCTestCase {
    func testDefaultLadderStepsDownInSeconds() {
        let ladder = HIDITConfig.default.ladder()
        XCTAssertEqual(ladder.intervals, [
            Interval(work: 180, recover: 120),
            Interval(work: 150, recover: 100),
            Interval(work: 120, recover: 80),
            Interval(work: 90, recover: 60),
            Interval(work: 60, recover: 40),
        ])
        XCTAssertFalse(ladder.clipped)
        XCTAssertEqual(ladder.intervals.totalSeconds, 1000) // 16:40
    }

    func testRecoveryIsAlwaysTwoThirdsOfWork() {
        for start in stride(from: 60, through: 600, by: 15) {
            for pct in stride(from: 5, through: 40, by: 5) {
                let ladder = HIDITConfig(startWork: start, steps: 10, stepDown: .percent(pct)).ladder()
                for interval in ladder.intervals {
                    XCTAssertEqual(interval.recover, Int((Double(interval.work) * 2 / 3).rounded()))
                }
            }
        }
    }

    func testPercentStepDown() {
        let ladder = HIDITConfig(startWork: 200, steps: 3, stepDown: .percent(10)).ladder()
        XCTAssertEqual(ladder.intervals.map(\.work), [200, 180, 162])
        XCTAssertEqual(ladder.intervals.map(\.recover), [133, 120, 108])
    }

    func testLadderStopsWhenWorkWouldFallUnderTenSeconds() {
        let ladder = HIDITConfig(startWork: 60, steps: 5, stepDown: .seconds(20)).ladder()
        XCTAssertEqual(ladder.intervals.map(\.work), [60, 40, 20])
        XCTAssertTrue(ladder.clipped)
    }

    func testTenSecondsOfWorkIsStillAllowed() {
        let ladder = HIDITConfig(startWork: 60, steps: 6, stepDown: .seconds(10)).ladder()
        XCTAssertEqual(ladder.intervals.map(\.work), [60, 50, 40, 30, 20, 10])
        XCTAssertFalse(ladder.clipped)
    }

    func testClampKeepsValuesInRange() {
        let c = HIDITConfig(startWork: 5, steps: 50, stepDown: .seconds(500)).clamped()
        XCTAssertEqual(c, HIDITConfig(startWork: 60, steps: 10, stepDown: .seconds(60)))
        let p = HIDITConfig(startWork: 900, steps: 0, stepDown: .percent(1)).clamped()
        XCTAssertEqual(p, HIDITConfig(startWork: 600, steps: 2, stepDown: .percent(5)))
    }

    func testSwitchingUnitResetsToDefault() {
        let c = HIDITConfig.default.withStepDownUnit(percent: true)
        XCTAssertEqual(c.stepDown, .percent(15))
        XCTAssertEqual(c.withStepDownUnit(percent: false).stepDown, .seconds(30))
    }

    func testFixedPresets() {
        let h = HIDITConfig.default, c = CustomConfig.default
        XCTAssertEqual(Preset.norwegian4x4.intervals(hidit: h, custom: c), Array(repeating: Interval(work: 240, recover: 180), count: 4))
        XCTAssertEqual(Preset.thirtyThirty.intervals(hidit: h, custom: c), Array(repeating: Interval(work: 30, recover: 30), count: 10))
        XCTAssertEqual(Preset.tabata.intervals(hidit: h, custom: c), Array(repeating: Interval(work: 20, recover: 10), count: 8))
        XCTAssertEqual(Preset.custom.intervals(hidit: h, custom: c), Array(repeating: Interval(work: 45, recover: 30), count: 6))
        XCTAssertEqual(Preset.allCases.map(\.name), ["HIDIT", "Norwegian 4x4", "30/30", "Tabata", "Custom"])
    }

    func testCustomClamp() {
        XCTAssertEqual(CustomConfig(work: 1, recover: 1, steps: 99).clamped(), CustomConfig(work: 10, recover: 5, steps: 20))
    }

    func testTimeFormat() {
        XCTAssertEqual(TimeFormat.clock(0), "0:00")
        XCTAssertEqual(TimeFormat.clock(45), "0:45")
        XCTAssertEqual(TimeFormat.clock(1000), "16:40")
        XCTAssertEqual(TimeFormat.displaySeconds(2.1), 3)
        XCTAssertEqual(TimeFormat.displaySeconds(3.0), 3)
        XCTAssertEqual(TimeFormat.displaySeconds(0), 0)
    }
}
