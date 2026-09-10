import AppKit
import Observation

@MainActor @Observable final class TimerStore {
    var model: TimerModel
    var entries: [TimeEntry] = []
    var wallTime = Date()
    var errorMessage: String?
    var day = Calendar.current.startOfDay(for: Date())
    var onUpdate: (() -> Void)?
    var onTransition: ((String) -> Void)?
    let database: Database
    private var timer: Timer?
    private var lastUptime: Double
    private var lastDate: Date
    private let now: () -> Date
    private let uptime: () -> Double
    private var segment: TimeEntry?
    private var sound: NSSound?
    init(database: Database, now: @escaping () -> Date = { Date() }, uptime: @escaping () -> Double = { ProcessInfo.processInfo.systemUptime }) throws {
        self.database = database
        self.now = now; self.uptime = uptime; lastDate = now(); lastUptime = uptime()
        model = try database.load() ?? TimerModel()
        wallTime = now()
        // A process restart is an interruption, never an inferred work session.
        model.running = false
        try database.save(model,entries:[])
        refresh()
    }
    var todayWork: Double { entries.filter{$0.phase == .work}.reduce(0){$0+$1.duration} }
    var todayRest: Double { entries.filter{$0.phase == .rest}.reduce(0){$0+$1.duration} }
    func startClock() {
        if let url = Bundle.main.url(forResource:"gentle-chime",withExtension:"wav") { sound = NSSound(contentsOf:url,byReference:true); sound?.volume = 0.35 }
        lastUptime = uptime(); lastDate = now()
        timer = Timer.scheduledTimer(withTimeInterval:1,repeats:true) { [weak self] _ in MainActor.assumeIsolated { self?.tick() } }
        timer?.tolerance = 0.1
        if let timer { RunLoop.main.add(timer,forMode:.common) }
    }
    func refresh() {
        day = Calendar.current.startOfDay(for:now())
        let end = Calendar.current.date(byAdding:.day,value:1,to:day)!
        do { entries = try database.entries(from:day,to:end) } catch { fail(error) }
    }
    private func fail(_ error: Error) { model.running = false; segment = nil; errorMessage = "Recording paused: \(error.localizedDescription)" }
    func persist(_ rows: [TimeEntry] = []) {
        do { try database.save(model,entries:rows) } catch { fail(error) }
        refresh(); onUpdate?()
    }
    func tick() {
        let now = now(), uptime = uptime()
        wallTime = now
        let dt = uptime - lastUptime, wall = now.timeIntervalSince(lastDate)
        defer { lastUptime = uptime; lastDate = now }
        guard model.running else { if Calendar.current.startOfDay(for:now) != day { refresh() }; return }
        // Sleep, suspension and wall-clock jumps cannot become invented ledger time.
        guard dt >= 0, dt < 10, abs(wall-dt) < 2 else { model.running = false; segment = nil; persist(); return }
        var left = dt, cursor = now.addingTimeInterval(-dt), rows: [TimeEntry] = [], messages: [String] = []
        while left > 0.000001 && model.running {
            if model.remaining <= 0.000001 { segment = nil; messages.append(model.finish()); continue }
            let used = min(left,model.remaining)
            if segment == nil { segment = TimeEntry(group:model.phase == .rest ? (model.restGroup ?? model.group) : model.group,task:model.phase == .rest ? "Rest" : model.task,phase:model.phase,start:cursor,end:cursor) }
            cursor = cursor.addingTimeInterval(used); segment!.end = cursor
            rows.append(segment!); model.elapsed += used; left -= used
            if model.remaining <= 0.000001 { segment = nil; messages.append(model.finish()) }
        }
        persist(rows)
        if errorMessage == nil { for message in messages { announce(message) } }
    }
    private func announce(_ message: String) {
        if model.settings.sound { sound?.play() }
        onTransition?(message)
    }
    func toggle() {
        tick(); guard errorMessage == nil else { return }
        model.toggle(); segment = nil; persist()
        if model.running && errorMessage == nil {
            announce(model.phase == .rest ? "Take a break" : "Back to work")
        }
    }
    func reset() { tick(); model.reset(); segment = nil; persist() }
    func pause() { tick(); model.running = false; segment = nil; persist() }
    func restart() {
        tick(); guard errorMessage == nil else { return }
        model.reset(); model.toggle(); segment = nil; persist()
        if model.running && errorMessage == nil { announce(model.phase == .rest ? "Take a break" : "Back to work") }
    }
    private func prepareDurationEdit(checkpoint: Bool) {
        if checkpoint { tick() }
        if !model.running { model.reset(); segment = nil }
    }
    func editWork(_ value: Double, checkpoint: Bool = true) {
        guard value.rounded() != model.work else { return }
        prepareDurationEdit(checkpoint:checkpoint); model.setWork(value)
        if checkpoint { persist() }
    }
    func editCycle(_ value: Double, checkpoint: Bool = true) {
        guard value.rounded() != model.cycle else { return }
        prepareDurationEdit(checkpoint:checkpoint); model.setCycle(value)
        if checkpoint { persist() }
    }
    func settings(_ update: (inout Settings) -> Void) { tick(); update(&model.settings); model.applyLimit(); persist() }
    func rename(_ name: String, new: Bool) {
        let clean = name.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        tick()
        if model.phase != .rest { segment = nil }
        model.task = clean
        if new { model.group = UUID().uuidString }
        persist()
    }
    func retry() {
        do {
            if let saved = try database.load() { model = saved; model.running = false }
            errorMessage = nil; segment = nil; persist()
        } catch { fail(error) }
    }
}
