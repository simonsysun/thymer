import Foundation
@main struct DragChecks {
    static func main() {
        func check(_ a:Double,_ b:Double) { precondition(abs(a-b)<1e-8,"\(a) != \(b)") }
        func move(_ d:inout DialDrag,_ angle:Double,_ radius:Double=140,_ offset:Double=0)->Double {
            d.move(angle:angle,radius:radius,lower:1,upper:120,offset:offset)
        }
        var linked=moveWorkEndpoint(work:50,rest:10,requested:55,maximum:120)
        check(linked.work,55);check(linked.rest,10)
        linked=moveWorkEndpoint(work:linked.work,rest:linked.rest,requested:40,maximum:120)
        check(linked.work,40);check(linked.rest,10)
        linked=moveWorkEndpoint(work:linked.work,rest:linked.rest,requested:65,maximum:120)
        check(linked.work,65);check(linked.rest,10)
        linked=moveWorkEndpoint(work:linked.work,rest:linked.rest,requested:60,maximum:120)
        check(linked.work,60);check(linked.rest,10)
        print("PASS: native Work carries unchanged Rest")
        let pushed=moveCycleEndpoint(work:50,requested:46,maximum:120)
        check(pushed.work,46);check(pushed.rest,0)
        let released=moveCycleEndpoint(work:pushed.work,requested:50,maximum:120)
        check(released.work,46);check(released.rest,4)
        print("PASS: Cycle pushes Work at zero Rest")
        var center=DialDrag(value:50)
        check(move(&center,300),50)
        check(move(&center,306,42),51)
        var precision=DialDrag(value:50)
        _=move(&precision,300,12)
        let near=move(&precision,306,12)
        precondition(near>50 && near<51)
        let fixed=move(&precision,0,0);check(move(&precision,180,0),fixed)
        check(move(&center,312,300),52);check(move(&center,318,600),53)
        var limit=DialDrag(value:119)
        check(move(&limit,354),119)
        for angle in [12.0,60,30,6] {check(move(&limit,angle),120)}
        check(move(&limit,354),119)
        var rotations=DialDrag(value:120)
        for angle in [30.0,120,210,300,30,90,150,210,270,330,350,10] {check(move(&rotations,angle),120)}
        check(move(&rotations,350),118+1.0/3)
        var rest=DialDrag(value:10)
        check(move(&rest,0,140,50),10);check(move(&rest,6,400,50),11)
        var low=DialDrag(value:1)
        for angle in [350.0,355,0] {check(move(&low,angle),1)}
        check(move(&low,12),2)
        print("PASS: native center damping, outer reach, boundary recapture, repeated overshoot, rest offset and minimum")
    }
}
