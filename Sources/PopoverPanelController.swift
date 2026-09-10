import AppKit
import SwiftUI

// Keep the fixed-size UI inside the standard AppKit content region.
// AppKit owns the arrow and outer margins; content must not extend into them.
@MainActor final class PopoverPanelController: NSViewController {
    private let host: NSHostingController<PanelView>
    init(store: TimerStore) {
        host = NSHostingController(rootView:PanelView(store:store))
        host.sizingOptions = []
        super.init(nibName:nil,bundle:nil)
        preferredContentSize = NSSize(width:360,height:488)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func loadView() {
        view = PanelBackground(frame:NSRect(x:0,y:0,width:360,height:488))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo:safe.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo:safe.trailingAnchor),
            host.view.topAnchor.constraint(equalTo:safe.topAnchor),
            host.view.bottomAnchor.constraint(equalTo:safe.bottomAnchor)
        ])
    }
}
private final class PanelBackground: NSView {
    override var isOpaque: Bool { true }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let dark = effectiveAppearance.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua
        (dark ? NSColor(srgbRed:0.145,green:0.153,blue:0.169,alpha:1) : NSColor(srgbRed:0.98,green:0.985,blue:0.995,alpha:1)).setFill()
        bounds.fill()
    }
}
