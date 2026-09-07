import Foundation

@main
struct EngineChecks {
    static func close(_ actual: Double, _ expected: Double, _ label: String) {
        precondition(abs(actual - expected) < 0.00001, "\(label): got \(actual), expected \(expected)")
    }
    static func main() {
        var passed = 0
        func check(_ name: String, _ test: () -> Void) { test(); passed += 1; print("PASS \(name)") }

        check("ready never accrues") {
            var clock = TimerEngine()
            precondition(clock.advance(600).isEmpty)
            close(clock.totalWork, 0, "ready work")
            close(clock.remaining, 3000, "initial remaining")
        }
        check("pause and resume preserve remaining and partial total") {
            var clock = TimerEngine(); clock.togglePlayback(); _ = clock.advance(17.25)
            clock.togglePlayback(); _ = clock.advance(500)
            close(clock.remaining, 2982.75, "paused remaining"); close(clock.totalWork, 17.25, "paused total")
            clock.togglePlayback(); _ = clock.advance(2.5)
            close(clock.totalWork, 19.75, "resumed total")
        }
        check("work ends exactly at boundary and enters rest") {
            var clock = TimerEngine(); clock.setWorkMinutes(1); clock.togglePlayback()
            precondition(clock.advance(60) == [.restStarted]); precondition(clock.phase == .rest)
            close(clock.elapsed, 0, "new rest progress"); close(clock.totalWork, 60, "work exact")
        }
        check("overshoot is attributed to rest rather than work") {
            var clock = TimerEngine(); clock.setWorkMinutes(1); clock.togglePlayback()
            precondition(clock.advance(67.5) == [.restStarted])
            close(clock.elapsed, 7.5, "rest overshoot"); close(clock.totalWork, 60, "no rest in work")
        }
        check("automatic loop carries time into next work") {
            var clock = TimerEngine(); clock.setWorkMinutes(1); clock.setRestMinutes(1); clock.togglePlayback()
            precondition(clock.advance(130) == [.restStarted, .workStarted])
            precondition(clock.phase == .work); close(clock.elapsed, 10, "next work"); close(clock.totalWork, 70, "two work pieces")
        }
        check("manual start waits without silently accruing") {
            var clock = TimerEngine(); clock.setWorkMinutes(1); clock.setRestMinutes(1); clock.autoStart = false; clock.togglePlayback()
            precondition(clock.advance(999) == [.restStarted, .waitingForStart]); precondition(clock.phase == .waiting)
            _ = clock.advance(1000); close(clock.totalWork, 60, "waiting total")
            clock.togglePlayback(); close(clock.remaining, 60, "new complete interval")
            _ = clock.advance(9); close(clock.totalWork, 69, "manual resumed total")
        }
        check("break pause freezes rest and does not count as work") {
            var clock = TimerEngine(); clock.setWorkMinutes(1); clock.togglePlayback(); _ = clock.advance(70)
            clock.togglePlayback(); _ = clock.advance(200)
            close(clock.elapsed, 10, "paused rest"); close(clock.totalWork, 60, "rest work total")
            clock.togglePlayback(); _ = clock.advance(5); close(clock.elapsed, 15, "rest resumed")
        }
        check("reset retains presets and partial recorded time") {
            var clock = TimerEngine(); clock.setWorkMinutes(90); clock.setRestMinutes(7); clock.togglePlayback(); _ = clock.advance(20)
            clock.reset(); precondition(clock.phase == .ready && !clock.isPaused)
            precondition(clock.workMinutes == 90 && clock.restMinutes == 7)
            close(clock.elapsed, 0, "reset elapsed"); close(clock.totalWork, 20, "reset saved partial")
        }
        check("task switching preserves attribution and locks running edits") {
            var clock = TimerEngine(); clock.setTaskName("Reading"); clock.togglePlayback(); _ = clock.advance(12)
            clock.setTaskName("Wrong"); clock.setWorkMinutes(5); clock.setRestMinutes(2)
            precondition(clock.taskName == "Reading" && clock.workMinutes == 50 && clock.restMinutes == 10)
            clock.reset(); clock.setTaskName("Writing"); clock.togglePlayback(); _ = clock.advance(8)
            close(clock.workByTask["Reading"]!, 12, "reading"); close(clock.workByTask["Writing"]!, 8, "writing")
        }
        check("empty task gets stable unnamed bucket") {
            var clock = TimerEngine(); clock.setTaskName("  "); clock.togglePlayback(); _ = clock.advance(3)
            close(clock.workByTask["未命名任务"]!, 3, "unnamed")
        }
        check("invalid and paused deltas are ignored") {
            var clock = TimerEngine(); clock.togglePlayback()
            for delta in [-1.0, 0.0, Double.infinity, Double.nan] { precondition(clock.advance(delta).isEmpty) }
            close(clock.elapsed, 0, "invalid delta"); close(clock.totalWork, 0, "invalid work")
        }
        check("minute limits include two complete turns") {
            var clock = TimerEngine(); clock.setWorkMinutes(121); clock.setRestMinutes(31)
            precondition(clock.workMinutes == 120 && clock.restMinutes == 30)
            clock.setWorkMinutes(0); clock.setRestMinutes(-10)
            precondition(clock.workMinutes == 1 && clock.restMinutes == 1)
        }
        check("dial unwrap keeps continuity across zero") {
            close(DialGeometry.shortestDelta(from: 354, to: 6), 12, "clockwise zero")
            close(DialGeometry.shortestDelta(from: 6, to: 354), -12, "reverse zero")
            close(DialGeometry.angle(minutes: 90) - DialGeometry.angle(minutes: 30), 360, "lap distinction")
        }
        check("preview jump does not credit skipped minutes") {
            var clock = TimerEngine(); clock.prepareBoundary(seconds: 3)
            close(clock.remaining, 3, "fixture remaining"); close(clock.totalWork, 0, "skipped total")
            precondition(clock.advance(3) == [.restStarted]); close(clock.totalWork, 3, "only actual preview time")
        }
        check("many small updates match one elapsed interval") {
            var small = TimerEngine(); var large = TimerEngine()
            small.setWorkMinutes(1); small.setRestMinutes(1); large = small
            small.togglePlayback(); large.togglePlayback()
            for _ in 0..<10000 { _ = small.advance(0.03) }
            _ = large.advance(300)
            close(small.totalWork, large.totalWork, "chunk invariant work")
            precondition(small.phase == large.phase); close(small.elapsed, large.elapsed, "chunk invariant progress")
        }
        check("changing auto-start during rest takes effect at boundary") {
            var clock = TimerEngine(); clock.setWorkMinutes(1); clock.setRestMinutes(1); clock.togglePlayback(); _ = clock.advance(70)
            clock.autoStart = false
            precondition(clock.advance(50) == [.waitingForStart]); precondition(!clock.isRunning)
        }
        print("\(passed) engine checks passed")
    }
}
