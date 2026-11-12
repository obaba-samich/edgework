import SwiftUI
import AudioToolbox

// MARK: - Aim trainer

struct AimTrainerView: View {
    @EnvironmentObject var store: Store

    enum Zone: String, CaseIterable, Identifiable {
        case topLeft, topRight, lowLeft, lowRight, fiveHole, topMiddle
        var id: String { rawValue }
        var title: String {
            switch self {
            case .topLeft: "Top left"
            case .topRight: "Top right"
            case .lowLeft: "Low left"
            case .lowRight: "Low right"
            case .fiveHole: "Five hole"
            case .topMiddle: "Bar down"
            }
        }
        var point: CGPoint {
            switch self {
            case .topLeft: CGPoint(x: 0.16, y: 0.22)
            case .topRight: CGPoint(x: 0.84, y: 0.22)
            case .lowLeft: CGPoint(x: 0.13, y: 0.82)
            case .lowRight: CGPoint(x: 0.87, y: 0.82)
            case .fiveHole: CGPoint(x: 0.5, y: 0.84)
            case .topMiddle: CGPoint(x: 0.5, y: 0.12)
            }
        }
    }

    @State private var zones: Set<Zone> = Set(Zone.allCases)
    @State private var interval = 4.0
    @State private var startedAt: Date?
    @State private var calls: [Zone] = []
    @State private var hits = 0
    @State private var misses = 0
    @State private var lastIndex = -1
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("Shooting", color: Color(hex: 0xB8F36B))
                    Text("Aim Trainer").font(.display(32)).foregroundStyle(Theme.text)
                    Text("A random target lights up. Hit it before the next call.").font(.subheadline).foregroundStyle(Theme.text2)
                }

                TimelineView(.periodic(from: .now, by: 0.1)) { tl in
                    let elapsed = startedAt.map { tl.date.timeIntervalSince($0) } ?? 0
                    let index = startedAt == nil ? -1 : Int(elapsed / interval)
                    let zone: Zone? = index >= 0 && index < calls.count ? calls[index] : nil
                    let phase = startedAt == nil ? 0 : (elapsed / interval).truncatingRemainder(dividingBy: 1)
                    VStack(spacing: 12) {
                        NetView(target: zone, enabled: zones, progress: phase)
                            .frame(height: 220)
                        Text(zone?.title.uppercased() ?? "READY")
                            .font(.display(40))
                            .foregroundStyle(zone == nil ? Theme.text3 : Color(hex: 0xB8F36B))
                            .contentTransition(.numericText())
                    }
                    .onChange(of: index) { _, new in
                        guard new != lastIndex, new >= 0 else { return }
                        lastIndex = new
                        if store.data.settings.sounds { AudioServicesPlaySystemSound(1057) }
                        store.haptic(.medium)
                    }
                }
                .cardStyle()

                HStack(spacing: 10) {
                    Button { hits += 1; store.haptic(.light) } label: {
                        VStack(spacing: 2) {
                            Text("\(hits)").font(.number(28))
                            Text("Hit").font(.caption.weight(.bold))
                        }
                        .frame(maxWidth: .infinity).frame(height: 76)
                        .foregroundStyle(Theme.bg)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.green))
                    }
                    Button { misses += 1; store.haptic(.light) } label: {
                        VStack(spacing: 2) {
                            Text("\(misses)").font(.number(28))
                            Text("Miss").font(.caption.weight(.bold))
                        }
                        .frame(maxWidth: .infinity).frame(height: 76)
                        .foregroundStyle(Theme.text)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface2))
                    }
                }
                .buttonStyle(PressableStyle())

                if hits + misses > 0 {
                    Text("Accuracy \(Int(Double(hits) / Double(hits + misses) * 100))% · \(hits + misses) shots")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text2)
                        .frame(maxWidth: .infinity)
                }

                HStack(spacing: 10) {
                    Button {
                        if startedAt == nil {
                            let pool = Array(zones.isEmpty ? Set(Zone.allCases) : zones)
                            var list: [Zone] = []
                            for _ in 0..<400 {
                                var z = pool.randomElement()!
                                if pool.count > 1 { while z == list.last { z = pool.randomElement()! } }
                                list.append(z)
                            }
                            calls = list
                            lastIndex = -1
                            startedAt = Date()
                            UIApplication.shared.isIdleTimerDisabled = true
                        } else {
                            startedAt = nil
                            UIApplication.shared.isIdleTimerDisabled = false
                        }
                    } label: { Label(startedAt == nil ? "Start calling" : "Stop", systemImage: startedAt == nil ? "play.fill" : "stop.fill") }
                        .buttonStyle(PrimaryButtonStyle(color: startedAt == nil ? Color(hex: 0xB8F36B) : Theme.red))
                    if hits + misses > 0 {
                        Button {
                            store.addShots(.wrist, hits + misses)
                            store.updateDaily { $0.onTarget += hits }
                            hits = 0
                            misses = 0
                            saved = true
                        } label: { Text("Log") }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(width: 90)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Call every").font(.headline).foregroundStyle(Theme.text)
                        Spacer()
                        TargetStepper(value: String(format: "%.1fs", interval), minus: { interval = max(1.5, interval - 0.5) }, plus: { interval = min(15, interval + 0.5) })
                    }
                    Overline("Targets")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(Zone.allCases) { z in
                            Button {
                                if zones.contains(z) { zones.remove(z) } else { zones.insert(z) }
                            } label: { Chip(text: z.title, color: Color(hex: 0xB8F36B), filled: zones.contains(z)) }
                                .buttonStyle(PressableStyle())
                        }
                    }
                }
                .cardStyle()
                .disabled(startedAt != nil)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .alert("Logged to your shot tracker", isPresented: $saved) { Button("OK", role: .cancel) {} }
    }
}

struct NetView: View {
    let target: AimTrainerView.Zone?
    let enabled: Set<AimTrainerView.Zone>
    var progress: Double = 0

    var body: some View {
        Canvas { ctx, size in
            let w = min(size.width, size.height * 1.5)
            let h = w / 1.5
            let rect = CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h)
            // Netting
            var net = Path()
            let step = w / 14
            var x = rect.minX
            while x <= rect.maxX { net.move(to: CGPoint(x: x, y: rect.minY)); net.addLine(to: CGPoint(x: x, y: rect.maxY)); x += step }
            var y = rect.minY
            while y <= rect.maxY { net.move(to: CGPoint(x: rect.minX, y: y)); net.addLine(to: CGPoint(x: rect.maxX, y: y)); y += step }
            ctx.stroke(net, with: .color(Color.white.opacity(0.07)), lineWidth: 1)
            // Frame: posts and crossbar
            var frame = Path()
            frame.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            frame.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            frame.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            frame.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            ctx.stroke(frame, with: .color(Theme.red), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            ctx.stroke(Path { p in p.move(to: CGPoint(x: rect.minX - 10, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.maxX + 10, y: rect.maxY)) },
                       with: .color(Theme.red.opacity(0.6)), lineWidth: 2)
            // Zones
            for z in AimTrainerView.Zone.allCases {
                let c = CGPoint(x: rect.minX + z.point.x * w, y: rect.minY + z.point.y * h)
                let r = w * 0.08
                let isTarget = z == target
                let circle = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                if isTarget {
                    let pulse = 1 + 0.25 * (1 - progress)
                    let outer = Path(ellipseIn: CGRect(x: c.x - r * pulse * 1.3, y: c.y - r * pulse * 1.3, width: r * 2.6 * pulse, height: r * 2.6 * pulse))
                    ctx.fill(outer, with: .color(Color(hex: 0xB8F36B).opacity(0.18)))
                    ctx.fill(circle, with: .color(Color(hex: 0xB8F36B)))
                } else {
                    ctx.stroke(circle, with: .color(enabled.contains(z) ? Color.white.opacity(0.25) : Color.white.opacity(0.06)), lineWidth: 2)
                }
            }
        }
    }
}

// MARK: - Hands caller

struct HandsCallerView: View {
    @EnvironmentObject var store: Store

    private static let moves: [(String, String)] = [
        ("Wide", "arrow.left.and.right"), ("Tight & fast", "bolt.fill"), ("Toe drag", "arrow.uturn.left"),
        ("Figure 8", "infinity"), ("Backhand only", "hand.raised.fill"), ("Forehand only", "hand.point.right.fill"),
        ("Between the legs", "arrow.down.to.line"), ("Eyes up!", "eye.fill"), ("Protect it", "shield.fill"),
        ("Top hand only", "1.circle.fill"), ("Around the puck", "arrow.triangle.2.circlepath"), ("Shoot!", "scope"),
    ]

    @State private var minutes = 5
    @State private var interval = 4.0
    @State private var startedAt: Date?
    @State private var calls: [Int] = []
    @State private var lastIndex = -1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("Stickhandling", color: Color(hex: 0xF5D76E))
                    Text("Hands Caller").font(.display(32)).foregroundStyle(Theme.text)
                    Text("Random moves called out. React without stopping.").font(.subheadline).foregroundStyle(Theme.text2)
                }

                TimelineView(.periodic(from: .now, by: 0.1)) { tl in
                    let elapsed = startedAt.map { tl.date.timeIntervalSince($0) } ?? 0
                    let total = Double(minutes * 60)
                    let running = startedAt != nil && elapsed < total
                    let index = running ? Int(elapsed / interval) : -1
                    let move = index >= 0 && index < calls.count ? Self.moves[calls[index]] : nil
                    VStack(spacing: 14) {
                        ZStack {
                            Ring(progress: startedAt == nil ? 0 : min(1, elapsed / total), color: Color(hex: 0xF5D76E), lineWidth: 10)
                            VStack(spacing: 8) {
                                Image(systemName: move?.1 ?? "figure.hockey")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(Color(hex: 0xF5D76E))
                                Text(move?.0 ?? (startedAt != nil && !running ? "Done!" : "Ready"))
                                    .font(.display(30))
                                    .foregroundStyle(Theme.text)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.6)
                                Text(Int(max(0, total - elapsed)).clock).font(.number(15)).foregroundStyle(Theme.text2)
                            }
                            .padding(30)
                        }
                        .frame(width: 250, height: 250)
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: index) { _, new in
                        guard new != lastIndex else { return }
                        lastIndex = new
                        if new >= 0 {
                            if store.data.settings.sounds { AudioServicesPlaySystemSound(1057) }
                            store.haptic(.medium)
                        } else if startedAt != nil {
                            store.updateDaily { $0.stickMinutes += minutes }
                            store.notify(.success)
                            UIApplication.shared.isIdleTimerDisabled = false
                        }
                    }
                }
                .cardStyle()

                Button {
                    if startedAt == nil {
                        calls = (0..<600).map { _ in Int.random(in: 0..<Self.moves.count) }
                        lastIndex = -1
                        startedAt = Date()
                        UIApplication.shared.isIdleTimerDisabled = true
                    } else {
                        startedAt = nil
                        UIApplication.shared.isIdleTimerDisabled = false
                    }
                } label: { Label(startedAt == nil ? "Start" : "Reset", systemImage: startedAt == nil ? "play.fill" : "arrow.counterclockwise") }
                    .buttonStyle(PrimaryButtonStyle(color: Color(hex: 0xF5D76E)))

                VStack(spacing: 12) {
                    HStack {
                        Text("Session").font(.headline).foregroundStyle(Theme.text)
                        Spacer()
                        TargetStepper(value: "\(minutes)m", minus: { minutes = max(1, minutes - 1) }, plus: { minutes = min(30, minutes + 1) })
                    }
                    HStack {
                        Text("New call every").font(.headline).foregroundStyle(Theme.text)
                        Spacer()
                        TargetStepper(value: String(format: "%.1fs", interval), minus: { interval = max(1.5, interval - 0.5) }, plus: { interval = min(15, interval + 0.5) })
                    }
                }
                .cardStyle()
                .disabled(startedAt != nil)

                Text("Finishing a session adds its minutes to your stickhandling goal.")
                    .font(.caption).foregroundStyle(Theme.text3)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}
