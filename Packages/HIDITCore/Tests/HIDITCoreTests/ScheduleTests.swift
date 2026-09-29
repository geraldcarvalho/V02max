import XCTest
@testable import HIDITCore

final class ScheduleTests: XCTestCase {
    let two = [Interval(work: 30, recover: 20), Interval(work: 25, recover: 15)]

    func testPhasesWithCountdown() {
        let s = Schedule(intervals: two, countdown: 10)
        XCTAssertEqual(s.phases.map(\.kind), [.ready, .work, .recover, .work, .recover])
        XCTAssertEqual(s.phases.map(\.start), [0, 10, 40, 60, 85])
        XCTAssertEqual(s.totalDuration, 100)
        XCTAssertEqual(s.phases[1].step, 1)
        XCTAssertEqual(s.phases[4].step, 2)
        XCTAssertEqual(s.phases[1].next, Phase.Next(kind: .recover, duration: 20))
        XCTAssertNil(s.phases[4].next)
    }

    func testNoCountdownWhenOff() {
        let s = Schedule(intervals: two, countdown: 0)
        XCTAssertEqual(s.phases.first?.kind, .work)
        XCTAssertEqual(s.totalDuration, 90)
    }

    func testPhaseIndex() {
        let s = Schedule(intervals: two, countdown: 10)
        XCTAssertEqual(s.phaseIndex(at: 0), 0)
        XCTAssertEqual(s.phaseIndex(at: 9.99), 0)
        XCTAssertEqual(s.phaseIndex(at: 10), 1)
        XCTAssertEqual(s.phaseIndex(at: 99.9), 4)
        XCTAssertNil(s.phaseIndex(at: 100))
    }

    func testPreRunCountdownCues() {
        let cues = Schedule(intervals: two, countdown: 10).cuePlan(CueOptions(ticks: true))
        let ready = cues.filter { $0.time < 10 }
        XCTAssertEqual(ready.map(\.time), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        XCTAssertEqual(ready.filter { $0.cue == .countdownTick }.count, 7) // 10 to 4
        XCTAssertEqual(ready.suffix(3).map(\.cue), [.countdownBeep(3), .countdownBeep(2), .countdownBeep(1)])
        XCTAssertEqual(cues.first { $0.time == 10 }?.cue, .runStart(step: 1))
    }

    func testCountdownBeepsStayWhenTicksOff() {
        let ready = Schedule(intervals: two, countdown: 5).cuePlan(CueOptions(ticks: false)).filter { $0.time < 5 }
        XCTAssertEqual(ready.map(\.cue), [.countdownBeep(3), .countdownBeep(2), .countdownBeep(1)])
    }

    func testShortPhasesSkipTicks() {
        let cues = Schedule(intervals: [Interval(work: 21, recover: 20)], countdown: 0).cuePlan(CueOptions(ticks: true))
        // 21 s work gets ticks into recover; 20 s recover does not.
        XCTAssertEqual(cues.map(\.cue), [
            .runStart(step: 1),
            .tickIntoRecover(3), .tickIntoRecover(2), .tickIntoRecover(1),
            .recoverStart(step: 1),
            .finish,
        ])
        XCTAssertEqual(cues.map(\.time), [0, 18, 19, 20, 21, 41])
    }

    func testTicksIntoRunDuringRecover() {
        let cues = Schedule(intervals: [Interval(work: 30, recover: 30)], countdown: 0).cuePlan(CueOptions(ticks: true))
        XCTAssertEqual(cues.filter { $0.time > 30 && $0.time < 60 }.map(\.cue), [.tickIntoRun(3), .tickIntoRun(2), .tickIntoRun(1)])
    }

    func testTicksOffLeavesOnlyPhaseCues() {
        let cues = Schedule(intervals: two, countdown: 0).cuePlan(CueOptions(ticks: false))
        XCTAssertEqual(cues.map(\.cue), [.runStart(step: 1), .recoverStart(step: 1), .runStart(step: 2), .recoverStart(step: 2), .finish])
    }

    func testBetween() {
        let cues = Schedule(intervals: two, countdown: 0).cuePlan(CueOptions(ticks: false))
        XCTAssertEqual(cues.between(0, 30).map(\.cue), [.recoverStart(step: 1)])
        XCTAssertEqual(cues.between(0, 30, includeLower: true).count, 2)
    }

    func testHIDITRepeatsTheLadder() {
        let ladder = HIDITConfig.default.intervals
        let s = Schedule(intervals: ladder, countdown: 10, rounds: 3)
        XCTAssertEqual(s.phases.count, 1 + 3 * 10)
        XCTAssertEqual(s.totalDuration, 10 + 3 * 725)
        // The last recover of round 1 (0:20) leads straight into round 2's 3:00 run.
        let end1 = s.phases[10]
        XCTAssertEqual(end1.kind, .recover)
        XCTAssertEqual(end1.round, 1)
        XCTAssertEqual(end1.duration, 20)
        XCTAssertEqual(end1.next, Phase.Next(kind: .work, duration: 180))
        XCTAssertEqual(s.phases[11].round, 2)
        XCTAssertEqual(s.phases[11].step, 1)
        XCTAssertEqual(s.phases[11].start, 10 + 725)
        XCTAssertEqual(s.phases.last?.totalRounds, 3)
    }

    func testStatsToAMomentInRoundTwo() {
        let s = Schedule(intervals: HIDITConfig.default.intervals, countdown: 10, rounds: 3)
        // Countdown, a full round, then 35 s into round 2's first run.
        let stats = s.stats(at: 10 + 725 + 35)
        XCTAssertEqual(stats.steps, 5)
        XCTAssertEqual(stats.workSeconds, 435 + 35)
        XCTAssertEqual(stats.recoverSeconds, 290)
        XCTAssertEqual(stats.longestWork, 180)
        XCTAssertEqual(stats.totalSeconds, 760)
        XCTAssertEqual(s.stats(at: 5), RunStats(steps: 0, workSeconds: 0, recoverSeconds: 0, longestWork: 0)) // still counting down
    }

    func testStatsCountsOnlyCompletedRecovers() {
        let s = Schedule(intervals: [Interval(work: 30, recover: 20)], countdown: 0)
        XCTAssertEqual(s.stats(at: 45).steps, 0)
        XCTAssertEqual(s.stats(at: 45).recoverSeconds, 15)
        XCTAssertEqual(s.stats(at: 50).steps, 1)
    }
}
