import Foundation

enum Phase: String, Codable { case ready, work, rest, waiting }
struct Settings: Codable {
    var animations: Bool? = nil
    var sound = true
    var autoStart = true
    var limit = true
    var theme = "System"
    var palette = "Blue gray"
}
struct TimerModel: Codable {
    var work = 50.0
    var rest = 10.0
    var phase = Phase.ready
    var running = false
    var elapsed = 0.0
    var task = "Reading"
    var group = UUID().uuidString
    var settings = Settings()
    var activeRest: Double? = nil
    var restGroup: String? = nil
    var statusSymbol: String { !running ? "pause.fill" : phase == .rest ? "cup.and.saucer" : "timer" }
    var cycle: Double { work + rest }
    var length: Double {
        if phase == .ready || phase == .waiting { return work > 0 ? work : rest }
        return phase == .rest ? rest : work
    }
    var remaining: Double { max(0, length * 60 - elapsed) }
    func minimum(_ kind: Phase) -> Double { phase == kind && elapsed > 0 ? floor(elapsed / 60) + 1 : 0 }
    func maximum(_ kind: Phase) -> Double {
        settings.limit ? max(120, phase == kind ? length : 0) : 525600
    }
    mutating func setWork(_ value: Double) { work = max(minimum(.work), min(maximum(.work), value.rounded())) }
    mutating func setCycle(_ value: Double) {
        let end = max(minimum(.work) + minimum(.rest), min(work + maximum(.rest), value.rounded()))
        work = max(minimum(.work), min(work, end - minimum(.rest)))
        rest = end - work
        if phase == .rest { activeRest = rest }
    }
    mutating func applyLimit() {
        if settings.limit {
            if phase != .work { work = min(120, work) }
            if phase != .rest { rest = min(120, rest) }
        }
    }
    mutating func toggle() {
        guard cycle > 0 else { return }
        if phase == .ready || phase == .waiting {
            phase = work > 0 ? .work : .rest; elapsed = 0
            activeRest = phase == .rest ? rest : nil
            restGroup = phase == .rest ? group : nil
        }
        running.toggle()
    }
    mutating func reset() { running = false; phase = .ready; elapsed = 0; activeRest = nil; applyLimit() }
    mutating func finish() -> String {
        let wasWork = phase == .work
        if settings.limit { if wasWork { work = min(120, work) } else { rest = min(120, rest) } }
        elapsed = 0
        if wasWork && rest > 0 { phase = .rest; activeRest = rest; restGroup = group; return "Take a break" }
        activeRest = nil
        if settings.autoStart && cycle > 0 {
            phase = work > 0 ? .work : .rest
            if phase == .rest { activeRest = rest; restGroup = group }
            return phase == .work ? "Back to work" : "Take a break"
        }
        running = false; phase = .waiting
        return "Cycle complete"
    }
}
struct TimeEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var group: String
    var task: String
    var phase: Phase
    var start: Date
    var end: Date
    var duration: Double { max(0, end.timeIntervalSince(start)) }
}
func shortDuration(_ seconds: Double) -> String {
    let minutes = Int(seconds / 60)
    if minutes >= 60 { return "\(minutes / 60)h" + (minutes % 60 > 0 ? " \(minutes % 60)m" : "") }
    return "\(minutes)m"
}
func countdown(_ seconds: Double) -> String {
    let s = Int(ceil(seconds))
    return s >= 3600 ? String(format:"%d:%02d:%02d",s/3600,s/60%60,s%60) : String(format:"%02d:%02d",s/60,s%60)
}
