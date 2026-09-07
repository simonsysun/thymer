import SwiftUI
import Observation
import AppKit

@MainActor @Observable
final class TimerStore {
    var engine = TimerEngine()
    var soundEnabled = true
    var accelerated = false
    var containsDemoData = false
    var banner: String?
    var bannerDetail = ""
    var settingsVisible = false
    @ObservationIgnored var onUpdate: (() -> Void)?
    @ObservationIgnored var onTransition: ((String, String) -> Void)?
    @ObservationIgnored private var pulse: Timer?
    @ObservationIgnored private var previousTime = ProcessInfo.processInfo.systemUptime
    @ObservationIgnored private var bannerUntil = 0.0
    @ObservationIgnored private var chime: NSSound?
    @ObservationIgnored private var panelVisible = false

    var phase: TimerPhase { engine.phase }
    var isPaused: Bool { engine.isPaused }
    var isRunning: Bool { engine.isRunning }
    var canEdit: Bool { engine.canEdit }
    var workMinutes: Int { engine.workMinutes }
    var restMinutes: Int { engine.restMinutes }
    var elapsed: Double { engine.elapsed }
    var remaining: Double { engine.remaining }
    var totalWork: Double { engine.totalWork }
    var taskName: String { engine.taskName }
    var autoStart: Bool { get { engine.autoStart } set { engine.autoStart = newValue } }
    var phaseTitle: String {
        if isPaused { return phase == .rest ? "休息已暂停" : "工作已暂停" }
        switch phase { case .ready: return "准备开始"; case .work: return "专注中"; case .rest: return "休息中"; case .waiting: return "待开始" }
    }
    var remainingText: String { Self.clock(remaining) }
    var totalText: String {
        let seconds = Int(totalWork)
        if seconds < 60 { return "\(seconds) 秒" }
        return seconds < 3600 ? "\(seconds / 60) 分钟" : "\(seconds / 3600) 小时 \(seconds % 3600 / 60) 分钟"
    }
    static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(ceil(seconds)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    func setWorkMinutes(_ value: Int) { engine.setWorkMinutes(value); onUpdate?() }
    func setRestMinutes(_ value: Int) { engine.setRestMinutes(value); onUpdate?() }
    func setTaskName(_ value: String) { engine.setTaskName(value) }
    func togglePlayback() { tick(); engine.togglePlayback(); banner = nil; onUpdate?() }
    func reset() { tick(); engine.reset(); banner = nil; onUpdate?() }
    func prepareBoundary() {
        tick()
        containsDemoData = true
        banner = nil
        engine.prepareBoundary(seconds: 3 * (accelerated ? 60 : 1))
        previousTime = ProcessInfo.processInfo.systemUptime
        onUpdate?()
    }
    func setAccelerated(_ value: Bool) {
        tick()
        accelerated = value
        if value { containsDemoData = true }
        previousTime = ProcessInfo.processInfo.systemUptime
    }
    func pauseForInterruption() {
        guard isRunning else { return }
        engine.pause()
        showBanner("计时已暂停", detail: "回来后点击继续", persistent: true)
        onUpdate?()
    }

    func startClock(chimeURL: URL?) {
        if let chimeURL { chime = NSSound(contentsOf: chimeURL, byReference: false) }
        previousTime = ProcessInfo.processInfo.systemUptime
        schedulePulse()
    }
    func setPanelVisible(_ value: Bool) {
        tick()
        panelVisible = value
        schedulePulse()
    }
    private func schedulePulse() {
        pulse?.invalidate()
        let timer = Timer(timeInterval: panelVisible ? 1.0 / 30.0 : 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = panelVisible ? 0.004 : 0.05
        RunLoop.main.add(timer, forMode: .common)
        pulse = timer
    }
    func playChime() { guard soundEnabled else { return }; chime?.stop(); chime?.volume = 0.35; chime?.play() }
    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let delta = max(0, now - previousTime)
        previousTime = now
        if delta > 5 && isRunning { pauseForInterruption(); return }
        for event in engine.advance(delta * (accelerated ? 60 : 1)) {
            switch event {
            case .restStarted: showBanner("起来活动一下", detail: "休息 \(restMinutes) 分钟")
            case .workStarted: showBanner("新一轮开始了", detail: engine.taskKey)
            case .waitingForStart: showBanner("休息结束，点击开始", detail: "下一轮 \(workMinutes) 分钟", persistent: true)
            }
            playChime()
        }
        if banner != nil && bannerUntil > 0 && now >= bannerUntil { banner = nil }
        onUpdate?()
    }
    private func showBanner(_ title: String, detail: String, persistent: Bool = false) {
        banner = title; bannerDetail = detail
        bannerUntil = persistent ? 0 : ProcessInfo.processInfo.systemUptime + 5
        onTransition?(title, detail)
    }
}
