import Foundation

struct DialDrag {
    var value: Double
    private let grabOffset: Double
    init(value:Double,grabAngle:Double? = nil) {
        self.value=value
        grabOffset = grabAngle.map { $0 - value * 6 } ?? 0
    }
    private var last: Double? = nil
    private var locked = false
    private var previousPoint: Position? = nil
    private struct Position { var x:Double;var y:Double }
    private func delta(_ from:Double,_ to:Double)->Double {
        var d=to-from;while d>180 {d-=360};while d < -180 {d+=360};return d
    }
    private func distance(_ a:Position,_ b:Position)->Double {
        let x=b.x-a.x,y=b.y-a.y,den=x*x+y*y
        let t=den>0 ? max(0,min(1,-(a.x*x+a.y*y)/den)) : 0
        return hypot(a.x+t*x,a.y+t*y)
    }
    mutating func move(angle:Double,radius:Double,lower:Double,upper:Double,offset:Double=0)->Double {
        // A forgiving hit area must not snap the hand to the initial click.
        let angle = angle - grabOffset
        value=max(lower,min(upper,value))
        if radius<0.001 {last=nil;previousPoint=nil;return value}
        let radians=angle * .pi / 180
        let position=Position(x:sin(radians)*radius,y:-cos(radians)*radius)
        let closest=previousPoint.map{distance($0,position)} ?? radius
        let t=min(1,max(0,min(radius,closest)/32)),gain=t*t*(3-2*t)
        let crossesCenter=closest<4
        previousPoint=position
        let target=(value+offset)*6
        let candidate:Double
        if locked {
            let gap=delta(angle,target)
            let travel=last.map{delta($0,angle)} ?? 0
            let toTarget=last.map{delta($0,target)} ?? 0
            let crossed = !crossesCenter && last != nil && abs(travel)>1e-9 && toTarget*travel>=0 && abs(toTarget)<=abs(travel)+1e-9
            last=angle
            if abs(gap)>0.5 && !crossed {return value}
            candidate=value+(crossed ? travel-toTarget : 0)/6
        } else {
            candidate=value+delta(target,angle)*gain/6
            last=angle
        }
        value=max(lower,min(upper,candidate))
        locked=candidate<lower-1e-9 || candidate>upper+1e-9
        return value
    }
}

func moveWorkEndpoint(work:Double,rest:Double,requested:Double,maximum:Double)->(work:Double,rest:Double) {
    return (max(0,min(maximum,requested.rounded())),rest)
}
func moveCycleEndpoint(work:Double,requested:Double,maximum:Double)->(work:Double,rest:Double) {
    let end=max(0,min(work+maximum,requested.rounded()))
    let nextWork=min(work,end)
    return (nextWork,end-nextWork)
}
