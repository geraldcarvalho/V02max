import XCTest
@testable import HIDITCore

final class RunSessionTests: XCTestCase {
    let intervals = [Interval(work: 30, recover: 20), Interval(work: 25, recover: 15)]

    func session(countdown: Int = 10, at now: TimeInterval = 1000) -> RunSession {
        RunSession(schedule: Schedule(intervals: intervals, countdown: countdown), options: CueOptions(ticks: true), startedAt: now)
    }

    func testSnapshotDuringWorkAndRecover() {
        let s = session()
        let work = s.snapshot(at: 1000 + 10 + 7.5)
        XCTAssertEqual(work.phase?.kind, .work)
        XCTAssertEqual(work.remaining, 22.5, accuracy: 1e-9)
        XCTAssertEqual(work.progress, 0.25, accuracy: 1e-9) // fills forward
        let recover = s.snapshot(at: 1000 + 40 + 5)
        XCTAssertEqual(recover.phase?.kind, .recover)
        XCTAssertEqual(recover.progress, 0.75, accuracy: 1e-9) // drains backward
    }

    func testPauseDuringCountdownCancels() {
        var s = session()
        s.pause(at: 1004)
        XCTAssertEqual(s.state, .cancelled)
    }

    func testPauseFreezesClock() {
        var s = session()
        s.pause(at: 1020)
        XCTAssertEqual(s.state, .paused)
        XCTAssertEqual(s.scheduleTime(at: 5000), 20, accuracy: 1e-9)
        XCTAssertNil(s.wallTime(forScheduleTime: 30))
    }

    func testResumeGivesThreeSecondReady() {
        var s = session()
        s.pause(at: 1020)
        s.resume(at: 2000)
        XCTAssertEqual(s.resumeCountdownRemaining(at: 2000) ?? -1, 3, accuracy: 1e-9)
        XCTAssertEqual(s.scheduleTime(at: 2002), 20, accuracy: 1e-9) // held during Ready
        XCTAssertNil(s.resumeCountdownRemaining(at: 2003))
        XCTAssertEqual(s.scheduleTime(at: 2005), 22, accuracy: 1e-9)
        XCTAssertEqual(s.wallTime(forScheduleTime: 40) ?? -1, 2023, accuracy: 1e-9)
    }

    func testPauseDuringResumeCountdownKeepsPosition() {
        var s = session()
        s.pause(at: 1020)
        s.resume(at: 2000)
        s.pause(at: 2001)
        XCTAssertEqual(s.state, .paused)
        XCTAssertEqual(s.scheduleTime(at: 3000), 20, accuracy: 1e-9)
    }

    func testSkipCountdown() {
        var s = session()
        s.skipCountdown(at: 1003)
        XCTAssertEqual(s.scheduleTime(at: 1003), 10, accuracy: 1e-9)
        XCTAssertEqual(s.snapshot(at: 1003).phase?.kind, .work)
        s.skipCountdown(at: 1010) // no effect outside the countdown
        XCTAssertEqual(s.scheduleTime(at: 1010), 17, accuracy: 1e-9)
    }

    func testFinishes() {
        var s = session()
        XCTAssertFalse(s.update(at: 1099))
        XCTAssertTrue(s.update(at: 1100))
        XCTAssertEqual(s.state, .finished)
        XCTAssertEqual(s.snapshot(at: 1200).state, .finished)
    }

    func testNoDriftOverThirtyMinutes() {
        // 30 minutes of intervals, read at irregular moments with pauses in between.
        let long = Array(repeating: Interval(work: 60, recover: 40), count: 18) // 1800 s
        var s = RunSession(schedule: Schedule(intervals: long, countdown: 0), options: CueOptions(ticks: true), startedAt: 0)
        var now: TimeInterval = 0
        var expected: TimeInterval = 0
        var reads = 0
        while expected < 1790 {
            let step = [0.016, 0.1, 0.333, 1.7, 4.2][reads % 5]
            now += step
            expected += step
            reads += 1
            if reads % 997 == 0 {
                s.pause(at: now)
                now += 12.34
                s.resume(at: now)
                now += RunSession.resumeCountdown
            }
            XCTAssertEqual(s.scheduleTime(at: now), min(expected, 1800), accuracy: 0.001)
        }
    }

    func testEmptyScheduleIsFinished() {
        let s = RunSession(schedule: Schedule(intervals: [], countdown: 10), options: CueOptions(ticks: true), startedAt: 0)
        XCTAssertEqual(s.state, .finished)
    }

    func testLastSecondsFlag() {
        let s = session()
        XCTAssertTrue(s.snapshot(at: 1000 + 38).isInLastSeconds)   // 2 s left of 30 s work
        XCTAssertFalse(s.snapshot(at: 1000 + 58).isInLastSeconds)  // 20 s recover skips ticks
    }
}
