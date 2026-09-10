import SwiftUI

struct CalendarPage: View {
    @Bindable var store: TimerStore
    let animations: Bool
    let close: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var viewport = TimelineViewport()
    var dayMinutes: Double { Calendar.current.date(byAdding:.day,value:1,to:store.day)!.timeIntervalSince(store.day)/60 }
    var collapse: Double { viewport.collapse }
    var blocks: [TimeEntry] {
        // Continue keeps one visible block when names change without a pause.
        var result: [TimeEntry] = []
        for entry in store.entries {
            if let last = result.last, last.group == entry.group, last.phase == entry.phase, abs(last.end.timeIntervalSince(entry.start)) < 0.01 {
                let i = result.count-1
                if entry.phase == .work && !result[i].task.components(separatedBy:" + ").contains(entry.task) { result[i].task += " + " + entry.task }
                result[i].end = entry.end
            } else { result.append(entry) }
        }
        return result
    }
    var body: some View {
        VStack(spacing:0) {
            VStack(alignment:.leading,spacing:10*(1-collapse)) {
                PanelToolbar {
                    PanelIcon("chevron.left",help:"Back to timer",action:close)
                    Text(dateLabel).font(.system(size:23-7*collapse,weight:.semibold)).lineLimit(1)
                    Spacer(minLength:0)
                    PanelIcon("minus",help:"Zoom out") { viewport.zoom(1/1.25) }.disabled(viewport.scale <= 0.75)
                    PanelIcon("plus",help:"Zoom in") { viewport.zoom(1.25) }.disabled(viewport.scale >= 5)
                }.buttonStyle(.plain)
                    HStack(spacing:20) {
                        total("Work",store.todayWork,Color(red:0.55,green:0.66,blue:0.83))
                        total("Rest",store.todayRest,.mint)
                    }.padding(.leading,56).frame(height:18*(1-collapse),alignment:.top).opacity(1-collapse).clipped()
            }.padding(.bottom,12*(1-collapse))
            Divider()
            TimelineScroll(viewport:viewport,minutes:dayMinutes,
                           initialMinute:(store.entries.first?.start ?? Date().addingTimeInterval(-1800)).timeIntervalSince(store.day)/60,
                           reduceMotion:!animations,content:{ scale in AnyView(timeline(scale).environment(\.colorScheme,scheme)) })
                .overlay { if store.entries.isEmpty { Text("No records yet").font(.system(size:13)).foregroundStyle(.secondary).padding(12).background(.regularMaterial,in:RoundedRectangle(cornerRadius:10)).allowsHitTesting(false) } }
        }
    }
    func timeline(_ scale:Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment:.topLeading) {
                ForEach(0..<Int(ceil(dayMinutes/60)),id:\.self) { hour in
                    let y = 20+Double(hour)*60*scale
                    Text(hourLabel(hour)).font(.system(size:10)).foregroundStyle(.secondary)
                        .frame(width:40,height:16,alignment:.trailing).position(x:24,y:y)
                    Path { p in p.move(to:CGPoint(x:54,y:y)); p.addLine(to:CGPoint(x:geometry.size.width-16,y:y)) }
                        .stroke(.secondary.opacity(0.18),lineWidth:0.5)
                }
                ForEach(blocks) { entry in
                    let y = 20+entry.start.timeIntervalSince(store.day)/60*scale
                    let height = max(1,entry.duration/60*scale)
                    event(entry,height:height).frame(width:max(0,geometry.size.width-70),height:height)
                        .offset(x:54,y:y)
                }
                let now = 20+store.wallTime.timeIntervalSince(store.day)/60*scale
                Path { p in p.move(to:CGPoint(x:54,y:now)); p.addLine(to:CGPoint(x:geometry.size.width-16,y:now)) }
                    .stroke(.red.opacity(0.45),lineWidth:0.5)
                Circle().fill(.red.opacity(0.75)).frame(width:5,height:5).position(x:54,y:now)
            }
        }
    }
    var dateLabel: String { let f = DateFormatter(); f.locale = Locale(identifier:"en_US"); f.dateFormat = "MMM d · EEE"; return f.string(from:store.day) }
    func hourLabel(_ hour:Int) -> String { let f = DateFormatter(); f.locale = Locale(identifier:"en_US"); f.dateFormat = "h a"; return f.string(from:store.day.addingTimeInterval(Double(hour)*3600)) }
    func time(_ date:Date) -> String { let f = DateFormatter(); f.locale = Locale(identifier:"en_US"); f.dateFormat = "h:mm a"; return f.string(from:date) }
    func total(_ label:String,_ seconds:Double,_ color:Color) -> some View {
        HStack(spacing:6) { Circle().fill(color).frame(width:5,height:5); Text(label).foregroundStyle(.secondary); Text(shortDuration(seconds)).fontWeight(.medium) }.font(.system(size:11))
    }
    func event(_ entry:TimeEntry,height:Double) -> some View {
        let color = entry.phase == .rest ? Color.mint : Color(red:0.55,green:0.66,blue:0.83)
        return VStack(alignment:.leading,spacing:3) {
            if height > 14 { Text(entry.phase == .rest ? "Rest · \(shortDuration(entry.duration))" : entry.task).font(.system(size:12,weight:.medium)).lineLimit(1) }
            if height > 40 { Text("\(time(entry.start))–\(time(entry.end)) · \(shortDuration(entry.duration))").font(.system(size:10)).foregroundStyle(.secondary).lineLimit(1) }
            Spacer(minLength:0)
        }.padding(.horizontal,9).padding(.top,height > 25 ? 6 : 0).frame(maxWidth:.infinity,alignment:.leading).frame(height:height)
            .background(color.opacity(0.25),in:RoundedRectangle(cornerRadius:5))
            .overlay(alignment:.leading) { RoundedRectangle(cornerRadius:2).fill(color).frame(width:2) }
            .clipped().help("\(entry.task) · \(time(entry.start))–\(time(entry.end)) · \(Int(entry.duration)) seconds")
    }
}
