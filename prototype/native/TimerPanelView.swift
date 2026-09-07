import SwiftUI

struct TimerPanelView: View {
    @Bindable var store: TimerStore

    var body: some View {
        Group {
            if store.settingsVisible { settings }
            else { timer }
        }
        .padding(16)
        .frame(width: 360)
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
    }

    private var timer: some View {
        VStack(spacing: 10) {
            HStack {
                Label(store.phaseTitle, systemImage: statusSymbol).font(.subheadline.weight(.semibold)).foregroundStyle(statusColor)
                Spacer()
                Button(action: store.reset) { Image(systemName: "arrow.counterclockwise") }
                    .help("重置本轮，保留今日累计").accessibilityLabel("重置本轮")
                Button { store.settingsVisible = true } label: { Image(systemName: "gearshape") }
                    .help("设置").accessibilityLabel("设置")
            }.buttonStyle(.borderless)

            if let banner = store.banner {
                Label { VStack(alignment: .leading, spacing: 1) { Text(banner); Text(store.bannerDetail).font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: "bell.badge") }
                    .font(.caption).padding(8).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.mint.opacity(0.16), in: RoundedRectangle(cornerRadius: 9))
                    .accessibilityElement(children: .combine)
            }
            DialView(store: store)
            HStack(spacing: 5) {
                minutesField("工作", value: Binding(get: { store.workMinutes }, set: store.setWorkMinutes))
                Text("·").foregroundStyle(.tertiary)
                minutesField("休息", value: Binding(get: { store.restMinutes }, set: store.setRestMinutes))
            }
            if store.workMinutes > 60 { Text("工作 \(store.workMinutes) 分钟 · \(store.workMinutes / 60) 圈 + \(store.workMinutes % 60) 分钟").font(.caption).foregroundStyle(.secondary) }
            VStack(alignment: .leading, spacing: 4) {
                Text("当前任务").font(.caption).foregroundStyle(.secondary)
                TextField("在做什么？", text: Binding(get: { store.taskName }, set: store.setTaskName))
                    .textFieldStyle(.roundedBorder).disabled(!store.canEdit).accessibilityLabel("当前任务")
            }
            HStack { Text(store.containsDemoData ? "演示累计" : "今日工作").foregroundStyle(.secondary); Spacer(); Text(store.totalText).monospacedDigit().fontWeight(.semibold) }
                .font(.footnote)
            if !store.canEdit { Text("重置后可调整时长和任务").font(.caption2).foregroundStyle(.secondary) }
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button { store.settingsVisible = false } label: { Label("返回", systemImage: "chevron.left") }.buttonStyle(.borderless)
            Text("设置").font(.title3.weight(.semibold))
            Toggle("提示音", isOn: $store.soundEnabled).accessibilityHint("阶段切换时播放轻柔提示音")
            Toggle("休息后自动开始工作", isOn: $store.autoStart).accessibilityHint("关闭后，休息结束会持续等待你开始")
            Text("阶段切换始终提醒，声音可以关闭。")
                .font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 170)
        }
        .toggleStyle(.switch)
    }

    private func minutesField(_ title: String, value: Binding<Int>) -> some View {
        HStack(spacing: 3) {
            Text(title)
            TextField("", value: value, formatter: NumberFormatter.minutes)
                .multilineTextAlignment(.center).frame(width: 37).disabled(!store.canEdit).accessibilityLabel("\(title)分钟")
            Text("分钟")
        }.font(.caption)
    }
    private var statusSymbol: String { store.phase == .rest ? "leaf.fill" : store.isRunning ? "circle.fill" : "circle" }
    private var statusColor: Color { store.phase == .rest ? .mint : store.isRunning ? .red : .secondary }
}

private extension NumberFormatter {
    static let minutes: NumberFormatter = { let f = NumberFormatter(); f.numberStyle = .none; f.allowsFloats = false; return f }()
}
