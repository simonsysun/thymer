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
        statusItem.autosaveName = "WorkRestTimerStatus"
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName:"timer",accessibilityDescription:"Thymer")
            button.imagePosition = .imageLeading; button.font = .monospacedDigitSystemFont(ofSize:12,weight:.medium)
            button.target = self; button.action = #selector(togglePopover)
        }
        popover.behavior = .transient; popover.delegate = self
        popover.hasFullSizeContent = false
        popover.contentSize = NSSize(width:360,height:488)
        popover.contentViewController = PopoverPanelController(store:store)
        store.onUpdate = { [weak self] in self?.updateStatus() }
        store.onTransition = { [weak self] message in self?.showNotice(message) }
        for name in [NSWorkspace.willSleepNotification,NSWorkspace.sessionDidResignActiveNotification,NSWorkspace.screensDidSleepNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName:name,object:nil,queue:.main) { [weak self] _ in MainActor.assumeIsolated { self?.store.pause() } })
        }
        store.startClock(); updateStatus()
        // QA callers must supply a fresh temporary data directory.
        if ProcessInfo.processInfo.arguments.contains("--qa-window"), ProcessInfo.processInfo.environment["WORK_REST_DATA_DIR"] != nil {
            let window = NSWindow(contentViewController:NSHostingController(rootView:PanelView(store:store)))
            window.title = "Thymer · Isolated preview"; window.styleMask = [.titled,.closable]
            window.setContentSize(NSSize(width:360,height:488)); window.center(); window.makeKeyAndOrderFront(nil)
            window.isReleasedWhenClosed = false; testWindow = window; NSApp.activate(ignoringOtherApps:true)
            DispatchQueue.main.async { window.makeFirstResponder(nil) }
        } else { DispatchQueue.main.asyncAfter(deadline:.now()+0.3) { self.showPopover() } }
    }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows flag:Bool) -> Bool {
        if !flag { showPopover() }; return true
    }
    func configureMenu() {
        let menu = NSMenu(); let app = NSMenuItem(); app.submenu = NSMenu()
        app.submenu?.addItem(withTitle:"Quit Thymer",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q"); menu.addItem(app)
        let edit = NSMenuItem(); edit.submenu = NSMenu(title:"Edit")
        for (title,selector,key) in [("Undo","undo:","z"),("Cut","cut:","x"),("Copy","copy:","c"),("Paste","paste:","v"),("Select All","selectAll:","a")] { edit.submenu?.addItem(withTitle:title,action:NSSelectorFromString(selector),keyEquivalent:key) }
        menu.addItem(edit)
        if ProcessInfo.processInfo.arguments.contains("--qa-window"), ProcessInfo.processInfo.environment["WORK_REST_DATA_DIR"] != nil {
            let qa = NSMenuItem(); qa.submenu = NSMenu(title:"Preview")
            qa.submenu?.addItem(withTitle:"Show menu panel",action:#selector(previewPopover),keyEquivalent:"p")
            qa.submenu?.addItem(withTitle:"Show phase notice",action:#selector(previewNotice),keyEquivalent:"n")
            menu.addItem(qa)
        }
        NSApp.mainMenu = menu
    }
    @objc func previewPopover() { showPopover() }
    @objc func previewNotice() { showNotice(store.model.phase == .rest ? "Take a break" : "Back to work") }
    func updateStatus() {
        guard let button = statusItem.button else { return }
        let symbol = store.model.statusSymbol
        if button.image?.name() != symbol {
            let image = NSImage(systemSymbolName:symbol,accessibilityDescription:symbol == "pause.fill" ? "Paused" : store.model.phase == .rest ? "Rest" : "Work")
            image?.size = NSSize(width:16,height:16)
            image?.isTemplate = true
            image?.setName(symbol)
            button.image = image
        }
        let time = countdown(store.model.remaining)
        button.title = " " + time
        // Reserve only the current digit count, independent of the phase glyph.
        let template = String(repeating:"0",count:time.count)
        let width = (template as NSString).size(withAttributes:[.font:button.font!]).width
        statusItem.length = ceil(width) + 16 + 4 + 12
        button.contentTintColor = store.model.phase == .rest ? .systemMint : nil
        let state = store.model.phase == .waiting ? "Ready for next cycle" : !store.model.running ? "Paused" : store.model.phase.rawValue.capitalized
        button.toolTip = "\(store.model.task) · \(state)"
        // Match the AppKit arrow/chrome to the same selected appearance as SwiftUI.
        popover.appearance = store.model.settings.theme == "System" ? nil : NSAppearance(named:store.model.settings.theme == "Dark" ? .darkAqua : .aqua)
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
        let content = NSHostingView(rootView:
            Button { [weak self, weak panel] in self?.showPopover(); panel?.orderOut(nil) } label: {
                PhaseNoticeContent(message:message,isRest:self.store.model.phase == .rest)
            }.buttonStyle(.plain))
        panel.contentView = content
        let size = content.fittingSize
        let frame = (statusItem.button?.window?.screen ?? NSScreen.main)!.visibleFrame
        panel.setFrame(NSRect(x:frame.maxX-size.width-16,y:frame.maxY-size.height-16,width:size.width,height:size.height),display:true)
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
