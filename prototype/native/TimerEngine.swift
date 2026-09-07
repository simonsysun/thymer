import Foundation

enum TimerPhase: String { case ready, work, rest, waiting }
enum TimerEvent: Equatable { case restStarted, workStarted, waitingForStart }

/// Value-type clock model. No persistence, UI, system clock or notification side effects.
struct TimerEngine {
    var phase: TimerPhase = .ready
    var isPaused = false
    private(set) var workMinutes = 50
    private(set) var restMinutes = 10
    private(set) var taskName = ""
    var autoStart = true
    private(set) var elapsed: Double = 0
    private(set) var workByTask: [String: Double] = [:]

    var isRunning: Bool { (phase == .work || phase == .rest) && !isPaused }
    var canEdit: Bool { phase == .ready }
    var duration: Double { Double(phase == .rest ? restMinutes : workMinutes) * 60 }
    var remaining: Double { max(0, duration - elapsed) }
    var totalWork: Double { workByTask.values.reduce(0, +) }
    var taskKey: String { taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未命名任务" : taskName }

    mutating func setWorkMinutes(_ minutes: Int) { if canEdit { workMinutes = min(120, max(1, minutes)) } }
    mutating func setRestMinutes(_ minutes: Int) { if canEdit { restMinutes = min(30, max(1, minutes)) } }
    mutating func setTaskName(_ name: String) { if canEdit { taskName = String(name.prefix(120)) } }

    mutating func togglePlayback() {
        switch phase {
        case .ready, .waiting: phase = .work; elapsed = 0; isPaused = false
        case .work, .rest: isPaused.toggle()
        }
    }

    mutating func reset() { phase = .ready; elapsed = 0; isPaused = false }
    mutating func pause() { if isRunning { isPaused = true } }

    /// Consume only running time, carrying overshoot into subsequent phases.
    mutating func advance(_ seconds: Double) -> [TimerEvent] {
        guard seconds.isFinite, seconds > 0, isRunning else { return [] }
        var left = seconds
        var events: [TimerEvent] = []
        while left > 0 && isRunning {
            let used = min(left, remaining)
            if phase == .work { workByTask[taskKey, default: 0] += used }
            elapsed += used
            left -= used
            if remaining <= 0.0000001 {
                elapsed = 0
                if phase == .work { phase = .rest; events.append(.restStarted) }
                else if autoStart { phase = .work; events.append(.workStarted) }
                else { phase = .waiting; events.append(.waitingForStart) }
            }
        }
        return events
    }

    /// Preview fixture: skip the drawing ahead, without crediting the skipped time.
    mutating func prepareBoundary(seconds: Double) {
        if phase == .ready || phase == .waiting { phase = .work }
        isPaused = false
        elapsed = max(0, duration - min(duration, max(0.01, seconds)))
    }
}

enum DialGeometry {
    static func angle(minutes: Double) -> Double { minutes * 6 - 90 }
    static func shortestDelta(from: Double, to: Double) -> Double {
        var delta = to - from
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }
}
