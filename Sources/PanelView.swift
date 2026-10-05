import SwiftUI
import AppKit

struct PanelView: View {
    @Bindable var store: TimerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var page = 0
    @State private var draft = ""
    @State private var editing = false
    @FocusState private var taskFocus: Bool
    var animations: Bool { store.model.settings.animations ?? !reduceMotion }
    var background: Color { scheme == .dark ? Color(red:0.145,green:0.153,blue:0.169) : Color(red:0.98,green:0.985,blue:0.995) }
    var body: some View {
        ZStack {
            timerPage.offset(x:page == 1 ? 14 : page == 2 ? -14 : 0).allowsHitTesting(page == 0).accessibilityHidden(page != 0)
            if page == 1 {
                CalendarPage(store:store,animations:animations,close:{ navigate(0) }).background(background)
                    .transition(animations ? .move(edge:.leading) : .opacity).zIndex(1)
            }
            if page == 2 {
                settingsPage.background(background).transition(animations ? .move(edge:.trailing) : .opacity).zIndex(2)
            }
        }
        .frame(width:360,height:488).background(background).clipped()
        .preferredColorScheme(store.model.settings.theme == "System" ? nil : store.model.settings.theme == "Dark" ? .dark : .light)
        .environment(\.locale,Locale(identifier:"en_US"))
        .alert("Recording paused",isPresented:Binding(get:{store.errorMessage != nil},set:{_ in})) {
            Button("Retry") { store.retry() }
            Button("Quit") { NSApp.terminate(nil) }
        } message: { Text(store.errorMessage ?? "") }
    }
    func navigate(_ destination:Int) {
        editing = false; taskFocus = false
        withAnimation(!animations ? .easeOut(duration:0.12) : .timingCurve(0.2,0.8,0.2,1,duration:0.28)) { page = destination }
    }
    var timerPage: some View {
        VStack(spacing:0) {
            HStack {
                Button { navigate(1) } label: { Image(systemName:"calendar") }.help("Today")
                Spacer()
                if !store.model.running && store.model.phase != .ready {
                    Text(store.model.phase == .waiting ? "Ready" : "Paused").font(.system(size:11)).foregroundStyle(.secondary)
                }
                Spacer()
                Button { store.reset() } label: { Image(systemName:"arrow.counterclockwise") }.help("Reset timer")
                Button { navigate(2) } label: { Image(systemName:"ellipsis") }.padding(.leading,10).help("Settings")
            }.buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size:16)).frame(height:34).padding(.horizontal,22).padding(.top,10)
            TimerDial(store:store)
            HStack {
                metric("Work",store.model.work); metric("Rest",store.model.rest); metric("Cycle",store.model.cycle)
            }.padding(.horizontal,22).padding(.bottom,16)
            Divider().padding(.horizontal,22)
            HStack(spacing:8) {
                TextField("What are you doing?",text:$draft)
                    .textFieldStyle(.plain).font(.system(size:14)).focused($taskFocus)
                    .onSubmit { saveName(false) }
                    .onChange(of:taskFocus) { _,focused in editing = focused; if focused { draft = store.model.task } }
                    .onExitCommand { draft = store.model.task; editing = false; taskFocus = false }
                    .accessibilityLabel("Task")
                if editing {
                    Button("Continue") { saveName(false) }
                    Button("New") { saveName(true) }
                } else {
                    Text("Today \(shortDuration(store.todayWork))").font(.system(size:12)).foregroundStyle(.secondary).fixedSize()
                }
            }.buttonStyle(.borderless).font(.system(size:11)).padding(.horizontal,22).frame(height:56)
        }.onAppear { draft = store.model.task }
    }
    func saveName(_ new:Bool) { store.rename(draft,new:new); draft = store.model.task; editing = false; taskFocus = false }
    func metric(_ label:String,_ minutes:Double) -> some View {
        VStack(alignment:.leading,spacing:5) {
            Text(label).font(.system(size:12)).foregroundStyle(.secondary)
            Text(shortDuration(minutes*60)).font(.system(size:16,weight:.medium)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
    func setting<Value>(_ key: WritableKeyPath<Settings,Value>) -> Binding<Value> {
        Binding(get:{store.model.settings[keyPath:key]},set:{ value in store.settings { $0[keyPath:key] = value } })
    }
    func switchRow(_ label:String,_ binding:Binding<Bool>) -> some View {
        HStack { Text(label); Spacer(); Toggle(label,isOn:binding).labelsHidden() }
    }
    var settingsPage: some View {
        VStack(alignment:.leading,spacing:0) {
            HStack {
                Text("Settings").font(.system(size:21,weight:.semibold)); Spacer()
                Button { navigate(0) } label: { Image(systemName:"chevron.right") }.buttonStyle(.plain).help("Back to timer")
            }.padding(.bottom,22)
            Text("Timer").font(.system(size:12)).foregroundStyle(.secondary).padding(.bottom,14)
            VStack(spacing:14) {
                switchRow("Sound",setting(\.sound))
                switchRow("Auto-start next cycle",setting(\.autoStart))
                switchRow("2h limit per phase",setting(\.limit))
            }.toggleStyle(.switch).controlSize(.small).font(.system(size:13))
            Divider().padding(.vertical,16)
            Text("Appearance").font(.system(size:12)).foregroundStyle(.secondary).padding(.bottom,14)
            Text("Theme").font(.system(size:13))
            Picker("Theme",selection:setting(\.theme)) {
                ForEach(["System","Light","Dark"],id:\.self) { Text($0).tag($0) }
            }.labelsHidden().pickerStyle(.segmented).frame(maxWidth:.infinity).padding(.top,8).padding(.bottom,14)
            Picker("Work color",selection:setting(\.palette)) {
                Text("Blue gray").tag("Blue gray"); Text("Warm gray").tag("Warm gray")
            }.font(.system(size:13))
            switchRow("Animations",Binding(get:{animations},set:{ value in store.settings { $0.animations = value } }))
                .toggleStyle(.switch).controlSize(.small).font(.system(size:13)).padding(.top,12)
            Spacer(minLength:12)
            HStack {
                Text("Work Rest Timer · 0.1.0").font(.system(size:11)).foregroundStyle(.tertiary)
                Spacer(); Button("Quit") { NSApp.terminate(nil) }.buttonStyle(.borderless).font(.system(size:12))
            }
        }.padding(24)
    }
}
