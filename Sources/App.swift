import AppKit
import SwiftUI

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var store: TimerStore!
    var statusItem: NSStatusItem!
    let popover = NSPopover()
    var toast: NSPanel?
    var toastDismiss: DispatchWorkItem?
    var observers: [NSObjectProtocol] = []
    var testWindow: NSWindow?
    func applicationDidFinishLaunching(_ notification:Notification) {
        NSApp.setActivationPolicy(.accessory)
        do {
            let override = ProcessInfo.processInfo.environment["WORK_REST_DATA_DIR"]
            let directory = override.map { URL(fileURLWithPath:$0,isDirectory:true) } ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Work Rest Timer",isDirectory:true)
            store = try TimerStore(database:Database(url:directory.appendingPathComponent("records.sqlite")))
        } catch {
            let alert = NSAlert(); alert.messageText = "Unable to open records"; alert.informativeText = error.localizedDescription; alert.runModal(); NSApp.terminate(nil); return
        }
        configureMenu()
        statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName:"timer",accessibilityDescription:"Work Rest Timer")
            button.imagePosition = .imageLeading; button.font = .monospacedDigitSystemFont(ofSize:12,weight:.medium)
            button.target = self; button.action = #selector(togglePopover)
        }
        popover.behavior = .transient; popover.delegate = self
        popover.contentSize = NSSize(width:360,height:488)
        popover.contentViewController = NSHostingController(rootView:PanelView(store:store))
        store.onUpdate = { [weak self] in self?.updateStatus() }
        store.onTransition = { [weak self] message in self?.showNotice(message) }
        for name in [NSWorkspace.willSleepNotification,NSWorkspace.sessionDidResignActiveNotification,NSWorkspace.screensDidSleepNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName:name,object:nil,queue:.main) { [weak self] _ in MainActor.assumeIsolated { self?.store.pause() } })
        }
        store.startClock(); updateStatus()
        // An explicit isolated QA mode; never runs against the normal database.
        if ProcessInfo.processInfo.arguments.contains("--qa-window"), ProcessInfo.processInfo.environment["WORK_REST_DATA_DIR"] != nil {
            let window = NSWindow(contentViewController:NSHostingController(rootView:PanelView(store:store)))
            window.title = "Work Rest Timer · Isolated preview"; window.styleMask = [.titled,.closable]
            window.setContentSize(NSSize(width:360,height:488)); window.center(); window.makeKeyAndOrderFront(nil)
            window.isReleasedWhenClosed = false; testWindow = window; NSApp.activate(ignoringOtherApps:true)
            DispatchQueue.main.async { window.makeFirstResponder(nil) }
        } else { DispatchQueue.main.asyncAfter(deadline:.now()+0.3) { self.showPopover() } }
    }
    func configureMenu() {
        let menu = NSMenu(); let app = NSMenuItem(); app.submenu = NSMenu()
        app.submenu?.addItem(withTitle:"Quit Work Rest Timer",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q"); menu.addItem(app)
        let edit = NSMenuItem(); edit.submenu = NSMenu(title:"Edit")
        for (title,selector,key) in [("Undo","undo:","z"),("Cut","cut:","x"),("Copy","copy:","c"),("Paste","paste:","v"),("Select All","selectAll:","a")] { edit.submenu?.addItem(withTitle:title,action:NSSelectorFromString(selector),keyEquivalent:key) }
        menu.addItem(edit); NSApp.mainMenu = menu
    }
    func updateStatus() {
        let paused = !store.model.running && store.model.phase != .ready
        statusItem.button?.title = " " + (paused ? "Ⅱ " : "") + countdown(store.model.remaining)
        statusItem.button?.contentTintColor = store.model.phase == .rest ? .systemMint : nil
        statusItem.button?.toolTip = "\(store.model.task) · \(store.model.phase.rawValue.capitalized)"
    }
    @objc func togglePopover() { if popover.isShown { popover.performClose(nil) } else { showPopover() } }
    func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps:true)
        popover.show(relativeTo:button.bounds,of:button,preferredEdge:.minY)
        popover.contentViewController?.view.window?.makeKey()
        popover.contentViewController?.view.window?.makeFirstResponder(nil)
    }
    func showNotice(_ message:String) {
        toastDismiss?.cancel(); toast?.orderOut(nil)
        let panel = NSPanel(contentRect:.zero,styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true; panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView:
            Button { [weak self, weak panel] in self?.showPopover(); panel?.orderOut(nil) } label: {
                HStack(spacing:12) { Image(systemName:self.store.model.phase == .rest ? "cup.and.saucer" : "timer"); Text(message); Spacer() }
                    .font(.system(size:14,weight:.medium)).foregroundStyle(self.store.model.phase == .rest ? Color.mint : Color.primary)
                    .padding(20).frame(width:280,height:66).background(.regularMaterial,in:RoundedRectangle(cornerRadius:18))
            }.buttonStyle(.plain))
        let frame = (statusItem.button?.window?.screen ?? NSScreen.main)!.visibleFrame
        panel.setFrame(NSRect(x:frame.maxX-296,y:frame.maxY-82,width:280,height:66),display:true)
        panel.orderFrontRegardless(); toast = panel
        let dismiss = DispatchWorkItem { [weak self, weak panel] in panel?.orderOut(nil); self?.toast = nil }
        toastDismiss = dismiss; DispatchQueue.main.asyncAfter(deadline:.now()+5,execute:dismiss)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification:Notification) {
        store?.pause(); for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        toastDismiss?.cancel()
    }
}
@main struct WorkRestTimer {
    @MainActor static func main() {
        let app = NSApplication.shared, delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
