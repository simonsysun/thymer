import AppKit
import SwiftUI
import Observation

@MainActor @Observable final class TimelineViewport {
    var scale = 2.0
    var collapse = 0.0
    var zoomRequest = 0
    var requestedScale = 2.0
    func zoom(_ factor:Double) {
        requestedScale = max(0.75,min(5,scale*factor)); zoomRequest += 1
    }
}

private final class TimelineScroller: NSScrollView {
    var onLayout: (() -> Void)?
    override func layout() { super.layout(); onLayout?() }
    var onMagnify: ((Double,Double) -> Void)?
    override func magnify(with event:NSEvent) {
        let local = contentView.convert(event.locationInWindow,from:nil)
        onMagnify?(1+event.magnification,local.y-contentView.bounds.minY)
    }
}

// AppKit owns the scroll bounds. Scale and anchor are changed together, after
// updating document geometry, so SwiftUI cannot clamp to the previous height.
struct TimelineScroll: NSViewRepresentable {
    var viewport: TimelineViewport
    var minutes: Double
    var initialMinute: Double
    var reduceMotion: Bool
    var content: (Double) -> AnyView
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context:Context) -> NSScrollView {
        let scroll = TimelineScroller()
        scroll.drawsBackground = false; scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .overlay; scroll.autohidesScrollers = true
        scroll.horizontalScrollElasticity = .none; scroll.verticalScrollElasticity = .automatic
        let document = NSHostingView(rootView:AnyView(EmptyView()))
        document.sizingOptions = []
        scroll.documentView = document
        context.coordinator.scroll = scroll; context.coordinator.document = document
        scroll.contentView.postsBoundsChangedNotifications = true
        context.coordinator.observer = NotificationCenter.default.addObserver(forName:NSView.boundsDidChangeNotification,object:scroll.contentView,queue:.main) { [weak coordinator = context.coordinator] _ in
            MainActor.assumeIsolated { coordinator?.didScroll() }
        }
        scroll.onLayout = { [weak coordinator = context.coordinator] in coordinator?.initializeIfNeeded() }
        scroll.onMagnify = { [weak coordinator = context.coordinator] factor,anchor in coordinator?.zoom(to:(coordinator?.parent.viewport.scale ?? 2)*factor,anchor:anchor,animated:false) }
        return scroll
    }
    func updateNSView(_ nsView:NSScrollView,context:Context) {
        let coordinator = context.coordinator; coordinator.parent = self
        coordinator.layout()
        coordinator.initializeIfNeeded()
        if coordinator.lastRequest != viewport.zoomRequest {
            coordinator.lastRequest = viewport.zoomRequest
            DispatchQueue.main.async { [weak coordinator] in
                guard let coordinator else { return }
                coordinator.zoom(to:self.viewport.requestedScale,anchor:(coordinator.scroll?.contentView.bounds.height ?? 300)/2,animated:!self.reduceMotion)
            }
        }
    }
    static func dismantleNSView(_ nsView:NSScrollView,coordinator:Coordinator) {
        coordinator.animation?.invalidate()
        if let observer = coordinator.observer { NotificationCenter.default.removeObserver(observer) }
    }
    @MainActor final class Coordinator {
        var parent: TimelineScroll
        weak var scroll: NSScrollView?
        var document: NSHostingView<AnyView>?
        var observer: NSObjectProtocol?
        var animation: Timer?
        var initialized = false
        var adjusting = false
        var lastRequest = 0
        var scrollOrigin = 0.0
        init(_ parent:TimelineScroll) { self.parent = parent }
        func initializeIfNeeded() {
            guard !initialized, let scroll, scroll.contentView.bounds.height > 20, scroll.contentView.bounds.width > 20 else { return }
            initialized = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.layout(); self.move(to:max(0,self.parent.initialMinute*self.parent.viewport.scale-30))
                self.scrollOrigin = Double(self.scroll?.contentView.bounds.minY ?? 0)
            }
        }
        func layout() {
            guard let scroll, let document else { return }
            adjusting = true
            let width = scroll.contentView.bounds.width
            let height = parent.minutes*parent.viewport.scale+40
            document.rootView = AnyView(parent.content(parent.viewport.scale).frame(width:width,height:height,alignment:.topLeading))
            document.setFrameSize(NSSize(width:width,height:height)); document.layoutSubtreeIfNeeded()
            adjusting = false
        }
        func move(to y:Double) {
            guard let scroll, let document else { return }
            adjusting = true
            scroll.contentView.scroll(to:NSPoint(x:0,y:max(0,min(document.frame.height-scroll.contentView.bounds.height,y))))
            scroll.reflectScrolledClipView(scroll.contentView)
            adjusting = false
        }
        func didScroll() {
            guard !adjusting, initialized, let scroll else { return }
            let distance = scroll.contentView.bounds.minY-scrollOrigin
            let collapse = max(0,min(1,distance/72))
            if abs(parent.viewport.collapse-collapse)>0.002 {
                // Avoid publishing from an AppKit layout callback.
                DispatchQueue.main.async { [weak self] in self?.parent.viewport.collapse = collapse }
            }
        }
        func zoom(to requested:Double,anchor:Double,animated:Bool) {
            guard let scroll else { return }
            animation?.invalidate()
            let start = parent.viewport.scale, end = max(0.75,min(5,requested))
            let minute = (scroll.contentView.bounds.minY+anchor-20)/start
            let began = ProcessInfo.processInfo.systemUptime
            let originalCollapse = parent.viewport.collapse
            func apply(_ value:Double) {
                parent.viewport.scale = value
                layout(); move(to:20+minute*value-anchor)
                // Zoom must not unexpectedly fold or unfold the header.
                scrollOrigin = (self.scroll?.contentView.bounds.minY ?? 0)-originalCollapse*72
            }
            guard animated else { apply(end); return }
            animation = Timer.scheduledTimer(withTimeInterval:1/60,repeats:true) { [weak self] timer in
                MainActor.assumeIsolated {
                    guard self != nil else { timer.invalidate(); return }
                    let t = min(1,(ProcessInfo.processInfo.systemUptime-began)/0.22)
                    let eased = 1-pow(1-t,3)
                    apply(start+(end-start)*eased)
                    if t>=1 { timer.invalidate() }
                }
            }
            if let animation { RunLoop.main.add(animation,forMode:.common) }
        }
    }
}
