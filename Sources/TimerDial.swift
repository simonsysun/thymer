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
struct TimerDial: View {
    @Bindable var store: TimerStore
    @Environment(\.colorScheme) private var scheme
    var work: Double { store.model.work }
    var rest: Double { store.model.rest }
    @State private var editing: Bool? = nil
    @State private var dragMotion: DialDrag? = nil
    var limit: Bool { store.model.settings.limit }
    @State private var dragEnd = 60.0
    @State private var dragRest = 10.0
    @State private var hovered: Bool? = nil
    var dark: Bool { scheme == .dark }
    var ink: Color { dark ? Color(white:0.92) : Color(red:0.27,green:0.32,blue:0.4) }
    var mint: Color { dark ? Color(red:0.44,green:0.79,blue:0.7) : Color(red:0.15,green:0.54,blue:0.44) }
    var workColor: Color { store.model.settings.palette == "Warm gray" ? Color(red:0.64,green:0.61,blue:0.57) : (dark ? Color(red:0.55,green:0.66,blue:0.83) : Color(red:0.44,green:0.56,blue:0.74)) }
    var visualWork:Double { editing == false ? (dragMotion?.value ?? work) : editing == true ? min(work,dragEnd) : work }
    var visualRest:Double { max(0,(editing == nil ? work+rest : dragEnd)-visualWork) }
    var body: some View {
            ZStack {
                Circle().fill(workColor.opacity(min(0.12,max(0,work/60-1)*0.04)))
                    .frame(width:268,height:268).blur(radius:12)
                Canvas { context, _ in
                    let work=visualWork,rest=visualRest
                    context.fill(Path(ellipseIn:CGRect(x:26,y:26,width:268,height:268)),with:.color(ink.opacity(0.025)))
                    let sectors = DialSectors(work:work,rest:rest,phase:store.model.phase,elapsed:store.model.elapsed)
                    paint(&context,start:sectors.workUsed.start,span:sectors.workUsed.span,r:inner,color:workColor,opacity:0.075)
                    paint(&context,start:sectors.workLeft.start,span:sectors.workLeft.span,r:inner,color:workColor,opacity:0.42)
                    paint(&context,start:sectors.restUsed.start,span:sectors.restUsed.span,r:outer,color:mint,opacity:0.075)
                    paint(&context,start:sectors.restLeft.start,span:sectors.restLeft.span,r:outer,color:mint,opacity:0.39)
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
    }
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
                store.tick()
                editing=selected;dragEnd=work+rest;dragRest=rest
                let start=value.startLocation
                dragMotion=DialDrag(value:selected ? work+rest : work,grabAngle:atan2(start.y-160,start.x-160)*180 / .pi+90)
            }
            guard let isRest=editing,var motion=dragMotion else {return}
            let x=value.location.x-160,y=value.location.y-160
            let minutes=motion.move(angle:atan2(y,x)*180 / .pi+90,radius:hypot(x,y),lower:store.model.running ? (isRest ? store.model.minimum(.work)+store.model.minimum(.rest) : store.model.minimum(.work)) : 0,upper:store.model.maximum(isRest ? .rest : .work)+(isRest ? work : 0))
            dragMotion=motion
            dragEnd=isRest ? minutes : minutes+dragRest
            if isRest { store.editCycle(minutes,checkpoint:false) } else { store.editWork(minutes,checkpoint:false) }
        }.onEnded {_ in editing=nil;dragMotion=nil;hovered=nil;store.tick();store.persist()}
    }
    var centerContent: some View {
        VStack(spacing:7) {
            if editing != nil {
                Text(duration(work).replacingOccurrences(of:" min",with:"m")).foregroundStyle(ink).accessibilityLabel("Work \(Int(work)) minutes")
                Text(duration(rest).replacingOccurrences(of:" min",with:"m")).foregroundStyle(mint).accessibilityLabel("Rest \(Int(rest)) minutes")
            } else {
                Image(systemName:store.model.running ? "pause.fill" : "play.fill").font(.system(size:23))
                Text(countdown(store.model.remaining)).font(.system(size:18,weight:.medium)).monospacedDigit()

            }
        }.font(.system(size:18,weight:.medium)).monospacedDigit().foregroundStyle(ink).frame(width:hub*2,height:hub*2)
    }
    var center: some View {
        ZStack {
            // Keep material outside the pressed label: plain Button dims its entire label.
            Circle().fill(.clear).frame(width:hub*2,height:hub*2)
                .glassEffect(.regular,in:.circle).allowsHitTesting(false)
            Circle().strokeBorder(mint.opacity(store.model.phase == .rest ? 0.85 : 0),lineWidth:1.5)
                .frame(width:hub*2,height:hub*2).allowsHitTesting(false)
            Button { store.toggle() } label: { centerContent.contentShape(Circle()) }
                .buttonStyle(QuietPressStyle()).disabled(editing != nil)
                .accessibilityLabel(store.model.running ? "Pause" : "Start")
                .accessibilityValue("\(store.model.phase.rawValue.capitalized), \(countdown(store.model.remaining)) remaining")
        }
    }
    func duration(_ minutes:Double)->String {
        let n=Int(minutes)
        return n>=60 ? "\(n/60)h" + (n%60>0 ? " \(n%60)m" : "") : "\(n) min"
    }
}
