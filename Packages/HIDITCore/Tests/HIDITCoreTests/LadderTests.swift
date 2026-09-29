import XCTest
@testable import HIDITCore

final class LadderTests: XCTestCase {
    /// The HIDIT format: 3:00/2:00, 2:00/1:20, 1:00/0:40, 0:45/0:30, 0:30/0:20.
    func testDefaultLadderIsTheHIDITFormat() {
        XCTAssertEqual(HIDITConfig.default.intervals, [
            Interval(work: 180, recover: 120),
            Interval(work: 120, recover: 80),
            Interval(work: 60, recover: 40),
            Interval(work: 45, recover: 30),
            Interval(work: 30, recover: 20),
        ])
        XCTAssertEqual(HIDITConfig.default.intervals.totalSeconds, 725) // 12:05
        XCTAssertEqual(HIDITConfig.default.intervals.workSeconds, 435)
        XCTAssertEqual(HIDITConfig.default.intervals.recoverSeconds, 290)
    }

    func testRecoveryIsAlwaysTwoThirdsOfWork() {
        for work in stride(from: 10, through: 600, by: 5) {
            let interval = HIDITConfig(works: [work, work]).intervals[0]
            XCTAssertEqual(interval.recover, Int((Double(work) * 2 / 3).rounded()))
        }
    }

    func testAdjustingWorkKeepsRatioAndRange() {
        var c = HIDITConfig.default.adjustingWork(at: 2, by: 5)
        XCTAssertEqual(c.intervals[2], Interval(work: 65, recover: 43))
        c = c.adjustingWork(at: 4, by: -100)
        XCTAssertEqual(c.works[4], 10)
        c = c.adjustingWork(at: 0, by: 1000)
        XCTAssertEqual(c.works[0], 600)
        XCTAssertEqual(c.adjustingWork(at: 9, by: 5), c) // out of range index is ignored
    }

    func testAddAndRemoveSteps() {
        var c = HIDITConfig.default.addingStep()
        XCTAssertEqual(c.works, [180, 120, 60, 45, 30, 15])
        c = c.addingStep()
        XCTAssertEqual(c.works.last, 10) // never below 10 s
        while c.works.count < 10 { c = c.addingStep() }
        XCTAssertEqual(c.addingStep().works.count, 10)
        var d = HIDITConfig(works: [60, 30, 20])
        d = d.removingLastStep()
        XCTAssertEqual(d.works, [60, 30])
        XCTAssertEqual(d.removingLastStep().works, [60, 30]) // at least two steps
    }

    func testClampFixesCountAndRange() {
        XCTAssertEqual(HIDITConfig(works: [5, 900]).clamped().works, [10, 600])
        XCTAssertEqual(HIDITConfig(works: [100]).clamped().works, [100, 85])
        XCTAssertEqual(HIDITConfig(works: Array(repeating: 60, count: 14)).clamped().works.count, 10)
    }

    func testFixedPresets() {
        let h = HIDITConfig.default, c = CustomConfig.default
        XCTAssertEqual(Preset.hidit.intervals(hidit: h, custom: c), h.intervals)
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
        XCTAssertEqual(TimeFormat.clock(725), "12:05")
        XCTAssertEqual(TimeFormat.displaySeconds(2.1), 3)
        XCTAssertEqual(TimeFormat.displaySeconds(3.0), 3)
        XCTAssertEqual(TimeFormat.displaySeconds(0), 0)
    }
}
