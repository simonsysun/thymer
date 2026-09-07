import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSWindowDelegate {
    let store = TimerStore()
    var statusItem: NSStatusItem!
    let popover = NSPopover()
    var controls: NSWindow!
    var toast: NSPanel?
    var toastDismiss: DispatchWorkItem?
    var workspaceObservers: [NSObjectProtocol] = []
    var lastStatusKey = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMainMenu()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "工作休息计时器")
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.target = self; button.action = #selector(togglePopover)
            button.toolTip = "Work Rest Timer · 交互预览"
        }
        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 360, height: 570)
        popover.contentViewController = NSHostingController(rootView: TimerPanelView(store: store))

        let companion = VStack(spacing: 0) {
            TimerPanelView(store: store)
            Divider()
            PreviewControls(store: store, openTimer: { [weak self] in self?.showPopover() }, quit: { NSApp.terminate(nil) })
        }
        controls = NSWindow(contentViewController: NSHostingController(rootView: companion))
        controls.title = "Work Rest Timer — 交互预览"
        controls.styleMask = [.titled, .closable, .miniaturizable]
        controls.setContentSize(NSSize(width: 360, height: 718))
        controls.isReleasedWhenClosed = false
        controls.delegate = self
        controls.center()
        controls.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        store.onUpdate = { [weak self] in self?.updateStatus() }
        store.onTransition = { [weak self] title, detail in self?.showToast(title, detail: detail) }
        store.startClock(chimeURL: Bundle.main.url(forResource: "gentle-chime", withExtension: "wav"))
        store.setPanelVisible(true)
        updateStatus()

        for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            workspaceObservers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.store.pauseForInterruption() }
            })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.showPopover() }
    }

    func updateStatus() {
        let title: String
        if store.phase == .waiting { title = " 待开始" }
        else if store.isPaused { title = " Ⅱ " + store.remainingText }
        else { title = " " + store.remainingText }
        let key = title + store.phaseTitle
        guard key != lastStatusKey else { return }
        lastStatusKey = key
        statusItem.button?.title = title
        statusItem.button?.contentTintColor = store.phase == .rest ? .systemMint : nil
        statusItem.button?.setAccessibilityLabel("工作休息计时器，\(store.phaseTitle)，\(store.remainingText)")
    }

    func configureMainMenu() {
        let menu = NSMenu()
        let application = NSMenuItem()
        let applicationMenu = NSMenu()
        applicationMenu.addItem(withTitle: "退出预览", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        application.submenu = applicationMenu
        menu.addItem(application)
        let edit = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        for (title, selector, key) in [("撤销", "undo:", "z"), ("剪切", "cut:", "x"), ("拷贝", "copy:", "c"), ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")] {
            editMenu.addItem(withTitle: title, action: NSSelectorFromString(selector), keyEquivalent: key)
        }
        edit.submenu = editMenu
        menu.addItem(edit)
        NSApp.mainMenu = menu
    }

    @objc func togglePopover() { if popover.isShown { popover.performClose(nil) } else { showPopover() } }
    func popoverDidShow(_ notification: Notification) { store.setPanelVisible(true) }
    func popoverDidClose(_ notification: Notification) { store.setPanelVisible(controls?.isVisible == true) }
    func windowWillClose(_ notification: Notification) { store.setPanelVisible(popover.isShown) }
    func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        // Only this disposable app's own UI state is logged for preview diagnostics.
        let diagnostic = "shown=\(popover.isShown) statusFrame=\(NSStringFromRect(button.window?.frame ?? .zero)) popoverFrame=\(NSStringFromRect(popover.contentViewController?.view.window?.frame ?? .zero))\n"
        try? diagnostic.write(toFile: "/private/tmp/work-rest-timer-native-preview/presentation.log", atomically: true, encoding: .utf8)
    }

    func showToast(_ title: String, detail: String) {
        toastDismiss?.cancel(); toast?.orderOut(nil)
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let view = PhaseToast(title: title, detail: detail, waiting: store.phase == .waiting, open: { [weak self] in self?.showPopover() })
        panel.contentView = NSHostingView(rootView: view)
        if let screen = statusItem.button?.window?.screen ?? NSScreen.main {
            let frame = screen.visibleFrame
            // Leave the actual popover unobstructed while it is open.
            let x = popover.isShown ? max(frame.minX + 16, frame.maxX - 720) : frame.maxX - 342
            panel.setFrame(NSRect(x: x, y: frame.maxY - 112, width: 326, height: 92), display: true)
        }
        panel.orderFrontRegardless()
        toast = panel
        let dismiss = DispatchWorkItem { [weak panel] in panel?.orderOut(nil) }
        toastDismiss = dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: dismiss)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) {
        for observer in workspaceObservers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        toastDismiss?.cancel()
    }
}

struct PreviewControls: View {
    @Bindable var store: TimerStore
    let openTimer: () -> Void
    let quit: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "slider.horizontal.3").foregroundStyle(.secondary)
                Text("交互预览").font(.headline)
                Spacer()
                Text("Mac 原生").font(.caption).foregroundStyle(.secondary)
            }
            Text("本次数据只在内存中，退出后清空。")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("60 倍速 · 演示数据", isOn: Binding(get: { store.accelerated }, set: { store.setAccelerated($0) }))
                .toggleStyle(.switch)
            HStack {
                Button("距阶段结束 3 秒") { store.prepareBoundary() }
                    .help("跳过中间动画，不把跳过的时间加入累计")
                Button { store.playChime() } label: { Image(systemName: "speaker.wave.2") }
                    .help("试听提示音；遵循声音开关")
            }
            HStack {
                Button("打开计时器", action: openTimer).buttonStyle(.borderedProminent).tint(.red)
                Spacer()
                Button("退出预览", action: quit).buttonStyle(.borderless).foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 360, alignment: .leading)
    }
}

struct PhaseToast: View {
    let title: String
    let detail: String
    let waiting: Bool
    let open: () -> Void
    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                Image(systemName: waiting ? "play.circle.fill" : "timer")
                    .font(.system(size: 26)).foregroundStyle(waiting ? Color.red : Color.mint)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: 14, weight: .semibold))
                    Text(detail).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }.padding(18).frame(width: 326, height: 92)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)，\(detail)，打开计时器")
    }
}

@main
struct PreviewMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
