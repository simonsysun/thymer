import SwiftUI
import AppKit

/// The visual dial deliberately keeps its accumulated angle separate from its on-screen angle.
/// This prevents a drag across 12 o'clock from turning 59 minutes into 1 minute.
struct DialView: View {
    @Bindable var store: TimerStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastWorkAngle: Double?
    @State private var lastRestAngle: Double?

    private let outerRadius: CGFloat = 112
    private let innerRadius: CGFloat = 91
    private let workColor = Color(red: 0.957, green: 0.341, blue: 0.341)

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            ZStack {
                Circle().stroke(.quaternary, style: StrokeStyle(lineWidth: 22))
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                workBand
                extraTurnBand
                Circle().stroke(.quaternary, style: StrokeStyle(lineWidth: 12))
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
                restBand

                handle(at: point(center, radius: outerRadius, minutes: Double(store.workMinutes)), size: CGSize(width: 15, height: 31), color: workColor, label: "设定工作时长")
                    .gesture(dragGesture(center: center, kind: .work))
                    .accessibilityHint(store.canEdit ? "拖动以设定 1 到 120 分钟" : "重置后可调整")
                handle(at: point(center, radius: innerRadius, minutes: Double(store.workMinutes + store.restMinutes)), size: CGSize(width: 13, height: 24), color: restIdleColor, label: "设定休息时长")
                    .gesture(dragGesture(center: center, kind: .rest))
                    .accessibilityHint(store.canEdit ? "拖动以设定 1 到 30 分钟" : "重置后可调整")

                VStack(spacing: 12) {
                    Text(store.remainingText).font(.system(size: 33, weight: .medium, design: .rounded)).monospacedDigit()
                    Button(action: store.togglePlayback) {
                        Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                            .font(.title3.weight(.semibold)).frame(width: 60, height: 60)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(store.isRunning ? "暂停计时" : "开始或继续计时")
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .accessibilityElement(children: .contain)
            .coordinateSpace(name: "timerDial")
        }
        .frame(width: 300, height: 300)
    }

    @ViewBuilder private var workBand: some View {
        let configuredEnd = min(60, Double(store.workMinutes)) / 60
        let consumedStart = store.phase == .work ? min(1, max(0, store.elapsed / 3600)) : (store.phase == .ready ? 0 : 1)
        Circle().trim(from: min(consumedStart, configuredEnd), to: configuredEnd).stroke(workColor.gradient, style: StrokeStyle(lineWidth: 22, lineCap: .butt))
            .rotationEffect(.degrees(-90)).frame(width: outerRadius * 2, height: outerRadius * 2)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: store.phase)
    }

    @ViewBuilder private var extraTurnBand: some View {
        let configuredEnd = max(0, min(60, Double(store.workMinutes - 60))) / 60
        let consumedStart = store.phase == .work ? min(1, max(0, (store.elapsed / 60 - 60) / 60)) : (store.phase == .ready ? 0 : 1)
        if store.workMinutes > 60 {
            Circle().trim(from: min(consumedStart, configuredEnd), to: configuredEnd).stroke(workColor.opacity(0.72), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90)).frame(width: 256, height: 256)
        }
    }

    @ViewBuilder private var restBand: some View {
        let restProgress = store.phase == .rest ? min(1, store.elapsed / Double(store.restMinutes * 60)) : (store.phase == .waiting ? 1 : 0)
        let start = Double(store.workMinutes % 60) / 60
        let span = Double(store.restMinutes) / 60
        ArcBand(start: start, span: span, progress: restProgress, color: restIdleColor, consumedColor: .mint)
    }

    private var restIdleColor: Color { colorScheme == .dark ? .white.opacity(0.78) : .gray.opacity(0.78) }

    private func handle(at point: CGPoint, size: CGSize, color: Color, label: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.width / 2, style: .continuous).fill(color)
                .overlay(RoundedRectangle(cornerRadius: size.width / 2).stroke(.primary.opacity(0.28)))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(Double(atan2(point.y - 150, point.x - 150)) * 180 / .pi + 90))
        }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
            .position(point)
            .accessibilityLabel(label)
    }

    private enum Handle { case work, rest }
    private func dragGesture(center: CGPoint, kind: Handle) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("timerDial")).onChanged { value in
            guard store.canEdit else { return }
            let raw = atan2(value.location.y - center.y, value.location.x - center.x) * 180 / .pi + 90
            let normalized = raw < 0 ? raw + 360 : raw
            switch kind {
            case .work:
                let previous = lastWorkAngle ?? Double(store.workMinutes) * 6
                let accumulated = previous + DialGeometry.shortestDelta(from: previous.truncatingRemainder(dividingBy: 360), to: normalized)
                let clamped = accumulated.clamped(to: 6...720)
                lastWorkAngle = clamped
                store.setWorkMinutes(Int((clamped / 6).rounded()))
            case .rest:
                let initial = Double(store.workMinutes + store.restMinutes) * 6
                let previous = lastRestAngle ?? initial
                let accumulated = previous + DialGeometry.shortestDelta(from: previous.truncatingRemainder(dividingBy: 360), to: normalized)
                let low = Double(store.workMinutes + 1) * 6
                let high = Double(store.workMinutes + 30) * 6
                let clamped = accumulated.clamped(to: low...high)
                lastRestAngle = clamped
                store.setRestMinutes(Int((clamped / 6).rounded()) - store.workMinutes)
            }
        }.onEnded { _ in lastWorkAngle = nil; lastRestAngle = nil }
    }

    private func point(_ center: CGPoint, radius: CGFloat, minutes: Double) -> CGPoint {
        let radians = DialGeometry.angle(minutes: minutes.truncatingRemainder(dividingBy: 60)) * .pi / 180
        return CGPoint(x: center.x + cos(radians) * radius, y: center.y + sin(radians) * radius)
    }
}

private struct ArcBand: View {
    let start, span, progress: Double
    let color, consumedColor: Color
    var body: some View {
        ZStack {
            ArcPath(start: start, span: span).stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .butt))
            ArcPath(start: start, span: span * progress).stroke(consumedColor, style: StrokeStyle(lineWidth: 12, lineCap: .butt))
        }
        .frame(width: 300, height: 300)
    }
}
private struct ArcPath: Shape {
    let start, span: Double
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.addArc(center: c, radius: min(rect.width, rect.height) / 2 - 59, startAngle: .degrees(start * 360 - 90), endAngle: .degrees((start + span) * 360 - 90), clockwise: false)
        return p
    }
}
private extension Comparable { func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) } }
