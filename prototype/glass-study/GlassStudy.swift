import AppKit
import SwiftUI

private let outer: CGFloat = 134
private let inner: CGFloat = 105.3
private let hub: CGFloat = 51.2
private func point(_ minutes: Double, _ radius: CGFloat) -> CGPoint {
    let a = (minutes.truncatingRemainder(dividingBy: 60) * 6 - 90) * .pi / 180
    return CGPoint(x: 160 + cos(a) * radius, y: 160 + sin(a) * radius)
}
private func wedge(_ start: Double, _ span: Double, _ r: CGFloat) -> Path {
    guard span > 0 else { return Path() }
    if span >= 60 { return Path(ellipseIn: CGRect(x:160-r,y:160-r,width:r*2,height:r*2)) }
    return Path { p in
        p.move(to: CGPoint(x:160,y:160)); p.addLine(to:point(start,r))
        p.addArc(center:CGPoint(x:160,y:160),radius:r,startAngle:.degrees(start*6-90),endAngle:.degrees((start+span)*6-90),clockwise:false)
        p.closeSubpath()
    }
}
private func hand(_ minutes: Double, _ radius: CGFloat, _ start:CGFloat = hub) -> Path {
    Path { p in p.move(to:point(minutes,start));p.addLine(to:point(minutes,radius)) }
}
struct DialStudy: View {
    let sample: Int
    let glass: Bool
    @Environment(\.colorScheme) private var scheme
    @State private var work = 50.0
    @State private var rest = 10.0
    @State private var editing: Bool? = nil
    @State private var dragMotion: DialDrag? = nil
    @State private var limit = true
    @State private var dragEnd = 60.0
    @State private var dragRest = 10.0
    @State private var hovered: Bool? = nil
    var dark: Bool { scheme == .dark }
    var ink: Color { dark ? Color(white:0.92) : Color(red:0.27,green:0.32,blue:0.4) }
    var mint: Color { dark ? Color(red:0.44,green:0.79,blue:0.7) : Color(red:0.15,green:0.54,blue:0.44) }
    var workColor: Color { dark ? Color(red:0.55,green:0.66,blue:0.83) : Color(red:0.44,green:0.56,blue:0.74) }
    var visualWork:Double { editing == false ? (dragMotion?.value ?? work) : editing == true ? min(work,dragEnd) : work }
    var visualRest:Double { max(0,(editing == nil ? work+rest : dragEnd)-visualWork) }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { reset() } label: { Image(systemName:"arrow.counterclockwise") }
                    .help("重置演示")
                Menu {
                    Toggle("单段最长 2 小时",isOn:$limit)
                        .onChange(of:limit) { _,on in if on { work=min(work,120);rest=min(rest,120) } }
                } label: { Image(systemName:"ellipsis") }.menuStyle(.borderlessButton).frame(width:25)
            }.buttonStyle(.plain).foregroundStyle(.secondary).frame(height:26).padding(.horizontal,20).padding(.top,16)
            ZStack {
                Circle().fill(workColor.opacity(min(0.12,max(0,work/60-1)*0.04)))
                    .frame(width:268,height:268).blur(radius:12)
                Canvas { context, _ in
                    let work=visualWork,rest=visualRest
                    context.fill(Path(ellipseIn:CGRect(x:26,y:26,width:268,height:268)),with:.color(ink.opacity(0.025)))
                    paint(&context,start:0,span:work,r:inner,color:workColor,opacity:0.42)
                    paint(&context,start:work,span:rest,r:outer,color:mint,opacity:0.39)
                    for radius in [outer,inner] {
                        context.stroke(Path(ellipseIn:CGRect(x:160-radius,y:160-radius,width:radius*2,height:radius*2)),with:.color(ink.opacity(0.10)),lineWidth:1)
                    }
                    for isRest in [false,true] {
                        let minute=isRest ? work+rest : work, radius=isRest ? outer : inner, color=isRest ? mint : ink
                        context.stroke(hand(minute,radius,isRest && rest<0.4 ? 113 : hub),with:.color(color),style:StrokeStyle(lineWidth:2,lineCap:.round))
                        let end=point(minute,radius), active=editing == isRest || hovered == isRest
                        let size:CGFloat=isRest ? (active ? 10 : 7) : (active ? 11 : 8)
                        if active {
                            context.fill(Path(ellipseIn:CGRect(x:end.x-11,y:end.y-11,width:22,height:22)),with:.color(color.opacity(0.14)))
                        }
                        context.fill(Path(ellipseIn:CGRect(x:end.x-size/2,y:end.y-size/2,width:size,height:size)),with:.color(color))
                    }
                }
                Color.clear.contentShape(Rectangle()).gesture(dialGesture)
                    .onContinuousHover(coordinateSpace:.named("dial")) { phase in
                        if editing == nil {
                            switch phase { case .active(let location): hovered=pickHand(location);case .ended:hovered=nil }
                        }
                    }
                center
            }.frame(width:320,height:320).coordinateSpace(name:"dial").padding(.top,3).padding(.bottom,10)
            HStack {
                summary("Work",work);summary("Rest",rest);summary("Cycle",work+rest)
            }.padding(.horizontal,20).padding(.bottom,15)
            HStack { Text("阅读");Spacer();Text("材质预览").foregroundStyle(.secondary) }
                .font(.system(size:13)).padding(.vertical,16).overlay(alignment:.top){Divider()}.padding(.horizontal,20)
        }
        .frame(width:360)
        .background(dark ? Color(red:0.145,green:0.153,blue:0.169) : Color(red:0.98,green:0.985,blue:0.995),in:RoundedRectangle(cornerRadius:18))
        .overlay(RoundedRectangle(cornerRadius:18).strokeBorder(ink.opacity(0.08),lineWidth:1))
        .onAppear { reset() }.onChange(of:sample){_,_ in reset()}
    }
    func summary(_ name:String,_ minutes:Double)->some View {
        VStack(alignment:.leading,spacing:4) {
            Text(name).font(.system(size:12)).foregroundStyle(.secondary)
            Text(duration(minutes).replacingOccurrences(of:" min",with:"m")).font(.system(size:15,weight:.medium)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }.tracking(0.15).frame(maxWidth:.infinity,alignment:.leading)
    }
    func reset() { work=Double(sample);rest=10;limit=sample<=120;editing=nil;dragMotion=nil;dragEnd=work+rest;hovered=nil }
    func paint(_ context: inout GraphicsContext, start:Double,span:Double,r:CGFloat,color:Color,opacity:Double) {
        let turns=floor(span/60), tail=span.truncatingRemainder(dividingBy:60)
        let accumulated=0.78*(1-pow(1-opacity/0.78,turns)), next=0.78*(1-pow(1-opacity/0.78,turns+1))
        for (duration,alpha) in [(turns>0 ? 60.0 : 0,accumulated),(tail,(next-accumulated)/(1-accumulated))] {
            var c=context;c.opacity=alpha
            c.fill(wedge(start,duration,r),with:.radialGradient(Gradient(stops:[.init(color:color.opacity(0.48),location:0),.init(color:color.opacity(0.85),location:0.7),.init(color:color,location:1)]),center:CGPoint(x:138,y:119),startRadius:0,endRadius:185))
        }
    }
    func pickHand(_ location:CGPoint)->Bool? {
        guard hypot(location.x-160,location.y-160)>hub else {return nil}
        let candidates=[false,true].map { isRest -> (Bool,Double,Double) in
            let minute=isRest ? visualWork+visualRest : visualWork
            let end=point(minute,isRest ? outer : inner),start=point(minute,isRest && visualRest<0.4 ? 113 : hub)
            let dx=end.x-start.x,dy=end.y-start.y
            let t=max(0,min(1,((location.x-start.x)*dx+(location.y-start.y)*dy)/(dx*dx+dy*dy)))
            return (isRest,hypot(location.x-end.x,location.y-end.y),hypot(location.x-start.x-t*dx,location.y-start.y-t*dy))
        }
        if let end=candidates.filter({$0.1<=15}).min(by:{$0.1<$1.1}) {return end.0}
        return candidates.filter({$0.2<=12}).min(by:{$0.2 == $1.2 ? $0.1<$1.1 : $0.2<$1.2})?.0
    }
    var dialGesture: some Gesture {
        DragGesture(minimumDistance:0,coordinateSpace:.named("dial")).onChanged { value in
            if dragMotion == nil {
                guard let selected=pickHand(value.startLocation) else {return}
                editing=selected;dragEnd=work+rest;dragRest=rest
                dragMotion=DialDrag(value:selected ? work+rest : work)
            }
            guard let isRest=editing,var motion=dragMotion else {return}
            let x=value.location.x-160,y=value.location.y-160
            let minutes=motion.move(angle:atan2(y,x)*180 / .pi+90,radius:hypot(x,y),lower:0,upper:(limit ? 120 : 1000000)+(isRest ? work : 0))
            dragMotion=motion
            dragEnd=isRest ? minutes : minutes+dragRest
            let next=isRest ? moveCycleEndpoint(work:work,requested:minutes,maximum:limit ? 120 : 1000000) : moveWorkEndpoint(work:work,rest:rest,requested:minutes,maximum:limit ? 120 : 1000000)
            work=next.work;rest=next.rest
        }.onEnded {_ in editing=nil;dragMotion=nil;hovered=nil}
    }
    var centerContent: some View {
        VStack(spacing:7) {
            if editing != nil {
                Text(duration(work).replacingOccurrences(of:" min",with:"m")).foregroundStyle(ink).accessibilityLabel("Work \(Int(work)) 分钟")
                Text(duration(rest).replacingOccurrences(of:" min",with:"m")).foregroundStyle(mint).accessibilityLabel("Rest \(Int(rest)) 分钟")
            } else {
                Image(systemName:"play.fill").font(.system(size:23))
                Text(String(format:"%02d:00",Int(work))).font(.system(size:18,weight:.medium)).monospacedDigit()
            }
        }.font(.system(size:18,weight:.medium)).monospacedDigit().foregroundStyle(ink).frame(width:hub*2,height:hub*2)
    }
    @ViewBuilder var center: some View {
        if glass {
            centerContent.glassEffect(.regular,in:.circle)
        } else {
            centerContent.background(dark ? Color(white:0.17) : Color(white:0.98),in:Circle())
                .overlay(Circle().strokeBorder(ink.opacity(0.13),lineWidth:1))
        }
    }
    func duration(_ minutes:Double)->String {
        let n=Int(minutes)
        return n>=60 ? "\(n/60)h" + (n%60>0 ? " \(n%60)m" : "") : "\(n) min"
    }
}
struct Study: View {
    @State private var sample=50
    @State private var glass=true
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack {
                Text("表盘 · 原生玻璃对照").font(.headline)
                Spacer()
                Picker("时长",selection:$sample) {
                    ForEach([1,50,60,120,180,240],id:\.self){ Text("\($0) 分钟").tag($0) }
                }.frame(width:170)
                Toggle("Liquid Glass",isOn:$glass).toggleStyle(.switch)
            }
            HStack(alignment:.top,spacing:24) {
                DialStudy(sample:sample,glass:glass).environment(\.colorScheme,.light)
                DialStudy(sample:sample,glass:glass).environment(\.colorScheme,.dark)
            }
            Text("仅比较材质与拨杆手感 · 可拖动 · 中央播放图标为位置示意，计时请用 HTML 预览")
                .font(.system(size:12)).foregroundStyle(.secondary)
        }.padding(24).background(Color(nsColor:.windowBackgroundColor))
    }
}
@MainActor final class Delegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window:NSWindow!
    func applicationDidFinishLaunching(_ notification:Notification) {
        NSApp.setActivationPolicy(.regular)
        let menu=NSMenu(),app=NSMenuItem();menu.addItem(app);app.submenu=NSMenu()
        app.submenu?.addItem(withTitle:"退出材质预览",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q");NSApp.mainMenu=menu
        window=NSWindow(contentViewController:NSHostingController(rootView:Study()))
        window.title="Work Rest Timer — 原生材质研究"
        window.styleMask=[.titled,.closable,.miniaturizable];window.isReleasedWhenClosed=false;window.delegate=self
        window.setContentSize(NSSize(width:792,height:612));window.center();window.makeKeyAndOrderFront(nil);NSApp.activate(ignoringOtherApps:true)
        try? String(window.windowNumber).write(toFile:"/private/tmp/work-rest-glass-study-window-id",atomically:true,encoding:.utf8)
    }
    func windowWillClose(_ notification:Notification) { NSApp.terminate(nil) }
}
@main struct Main {
    @MainActor static func main() { let delegate=Delegate();NSApplication.shared.delegate=delegate;NSApplication.shared.run() }
}
