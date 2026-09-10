import SwiftUI
import AppKit

struct PanelView: View {
    @Bindable var store: TimerStore
    @Environment(\.colorScheme) private var scheme
    @State private var page = 0
    @State private var draft = ""
    @State private var editing = false
    @FocusState private var taskFocus: Bool
    // Smooth navigation is an explicit product preference; legacy saved values remain decodable.
    var animations: Bool { true }
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
        .frame(width:360,height:488).clipped().background(background.ignoresSafeArea())
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
            PanelToolbar {
                PanelIcon("calendar",help:"Today") { navigate(1) }
                Spacer()
                Button { store.restart() } label: {
                    Label("Restart",systemImage:"arrow.counterclockwise")
                        .font(.system(size:12)).padding(.horizontal,8).frame(height:40)
                        .contentShape(Rectangle())
                }.buttonStyle(QuietPressStyle()).foregroundStyle(.secondary)
                    .help("Start a full new cycle. Saved records are kept.")
                    .accessibilityLabel("Restart cycle").disabled(store.model.cycle == 0)
                PanelIcon("ellipsis",help:"Settings") { navigate(2) }
            }
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
            .toggleStyle(.switch).controlSize(.small).frame(height:49)
    }
    func group<Content:View>(@ViewBuilder content:()->Content) -> some View {
        VStack(spacing:0,content:content).padding(.horizontal,12)
            .background(.regularMaterial,in:RoundedRectangle(cornerRadius:12))
            .overlay { RoundedRectangle(cornerRadius:12).strokeBorder(.primary.opacity(0.07),lineWidth:0.5) }
    }
    var settingsPage: some View {
        VStack(alignment:.leading,spacing:0) {
            PanelToolbar {
                Text("Settings").font(.system(size:20,weight:.medium)).padding(.leading,4)
                Spacer()
                PanelIcon("chevron.right",help:"Back to timer") { navigate(0) }
            }
            VStack(alignment:.leading,spacing:8) {
                Text("Timer").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary)
                group {
                    switchRow("Sound",setting(\.sound))
                    Divider()
                    switchRow("Auto-start next cycle",setting(\.autoStart))
                    Divider()
                    switchRow("2h limit per phase",setting(\.limit))
                }
                Text("Appearance").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).padding(.top,10)
                group {
                    VStack(alignment:.leading,spacing:10) {
                        Text("Theme")
                        HStack(spacing:3) {
                            ForEach(["System","Light","Dark"],id:\.self) { theme in
                                Button { store.settings { $0.theme = theme } } label: {
                                    Text(theme).font(.system(size:11)).frame(maxWidth:.infinity).frame(height:26)
                                        .background(.primary.opacity(store.model.settings.theme == theme ? 0.10 : 0),in:RoundedRectangle(cornerRadius:6))
                                        .contentShape(Rectangle())
                                }.buttonStyle(QuietPressStyle())
                                    .accessibilityAddTraits(store.model.settings.theme == theme ? [.isSelected] : [])
                            }
                        }.padding(3).background(.primary.opacity(0.035),in:RoundedRectangle(cornerRadius:8))

                    }.padding(.vertical,12)
                    Divider()
                    HStack {
                        Text("Work color")
                        Spacer()
                        Picker("Work color",selection:setting(\.palette)) {
                            Text("Blue gray").tag("Blue gray"); Text("Warm gray").tag("Warm gray")
                        }.labelsHidden().fixedSize().controlSize(.small)
                    }.frame(height:49)
                }
            }.font(.system(size:12)).padding(.horizontal,20).padding(.top,17)
            Spacer(minLength:12)
            HStack {
                Text("Thymer · 0.1.0").font(.system(size:11)).foregroundStyle(.tertiary)
                    .help("Build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "local")")
                Spacer(); Button("Quit") { NSApp.terminate(nil) }.buttonStyle(.borderless).font(.system(size:12))
            }.padding(.horizontal,24).padding(.bottom,20)
        }
    }
}

// One geometry for both entrances and their same-side return controls.
struct PanelToolbar<Content:View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing:0,content:content).frame(height:40).padding(.horizontal,16).padding(.top,4)
    }
}
struct PanelIcon: View {
    let symbol: String
    let help: String
    let action: () -> Void
    init(_ symbol:String,help:String,action:@escaping ()->Void) {
        self.symbol=symbol; self.help=help; self.action=action
    }
    var body: some View {
        Button(action:action) {
            Image(systemName:symbol).font(.system(size:15,weight:.regular))
                .frame(width:40,height:40).contentShape(Rectangle())
        }.buttonStyle(QuietPressStyle()).foregroundStyle(.secondary).help(help).accessibilityLabel(help)
    }
}
struct QuietPressStyle: ButtonStyle {
    func makeBody(configuration:Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration:0.10),value:configuration.isPressed)
    }
}
