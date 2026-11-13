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
        var short: String {
            switch self {
            case .topLeft: "TL"
            case .topRight: "TR"
            case .lowLeft: "LL"
            case .lowRight: "LR"
            case .fiveHole: "5H"
            case .topMiddle: "BD"
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

    /// One called shot: a shot type at a target.
    struct Shot: Hashable {
        var type: ShotType
        var zone: Zone
        var text: String { "\(type.rawValue):\(zone.rawValue)" }
        init(type: ShotType, zone: Zone) { self.type = type; self.zone = zone }
        init?(_ s: Substring) {
            let p = s.split(separator: ":")
            guard p.count == 2, let t = ShotType(rawValue: String(p[0])), let z = Zone(rawValue: String(p[1])) else { return nil }
            type = t; zone = z
        }
    }

    enum Phase { case setup, calling, pickup, done }

    private static let lime = Color(hex: 0xB8F36B)

    @AppStorage("aimRandomize") private var randomize = true
    @AppStorage("aimUseCustom") private var useCustom = false
    @AppStorage("aimCustomShots") private var customRaw = ""
    @AppStorage("aimGoal") private var goal = 50
    @AppStorage("aimInterval") private var interval = 4.0
    @AppStorage("puckShotType") private var fixedType = ShotType.wrist
    @State private var zones: Set<Zone> = Set(Zone.allCases)
    @State private var types: Set<ShotType> = [.wrist, .snap, .backhand]
    @State private var newType = ShotType.wrist
    @State private var newZone = Zone.topLeft

    @State private var phase = Phase.setup
    @State private var calls: [Shot] = []
    @State private var bucketStart: Date?
    @State private var bucketSize = 0
    @State private var called = 0          // shots called so far this session
    @State private var shotsBefore = 0     // shots called before this bucket
    @State private var byType: [ShotType: Int] = [:]
    @State private var hits = 0
    @State private var misses = 0
    @State private var lastIndex = -1
    @State private var pickedUp = 0
    @State private var lost = 0
    @State private var logged = false

    private var custom: [Shot] {
        get { customRaw.split(separator: ",").compactMap(Shot.init) }
        nonmutating set { customRaw = newValue.map(\.text).joined(separator: ",") }
    }
    private var pucks: Int { store.data.settings.puckCount }
    private var activePucks: Int { max(0, pucks - lost) }
    private var remaining: Int { max(0, goal - called) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("Shooting", color: Self.lime)
                    Text("Aim Trainer").font(.display(32)).foregroundStyle(Theme.text)
                    Text("A target and shot get called. Shoot a bucket, pick them up, repeat. Every shot counts toward today.")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                }
                progressCard
                switch phase {
                case .setup: setup
                case .calling: calling
                case .pickup:
                    PuckPickupPanel(inHand: bucketSize, pickedUp: $pickedUp, isLast: remaining == 0,
                                    onLost: { lost += $0 }, onNext: nextBucket)
                case .done: done
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if phase == .calling || phase == .pickup {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End & log") { finish() }
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            if phase == .calling || phase == .pickup { logShots() }
        }
    }

    // MARK: Pieces

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Ring(progress: Double(called) / Double(max(1, goal)), color: Self.lime, lineWidth: 12)
                VStack(spacing: 0) {
                    Text("\(called)").font(.number(34, .heavy)).foregroundStyle(Theme.text).contentTransition(.numericText())
                    Text("of \(goal)").font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
                }
            }
            .frame(width: 110, height: 110)
            VStack(alignment: .leading, spacing: 8) {
                row("Pucks in play", "\(activePucks)", Theme.text)
                row("Rounds left", "\(activePucks == 0 ? 0 : Int((Double(remaining) / Double(activePucks)).rounded(.up)))", Theme.text)
                if hits + misses > 0 { row("Accuracy", "\(Int(Double(hits) / Double(hits + misses) * 100))%", Theme.green) }
                if lost > 0 { row("Lost", "\(lost)", Theme.red) }
            }
        }
        .cardStyle()
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.text2)
            Spacer()
            Text(value).font(.number(16)).foregroundStyle(color)
        }
    }

    private var setup: some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                HStack {
                    Text("Shots to take").font(.headline).foregroundStyle(Theme.text)
                    Spacer()
                    TargetStepper(value: "\(goal)", minus: { goal = max(5, goal - 5) }, plus: { goal = min(2000, goal + 5) })
                }
                HStack {
                    Text("Pucks I have").font(.headline).foregroundStyle(Theme.text)
                    Spacer()
                    TargetStepper(value: "\(pucks)", minus: { store.data.settings.puckCount = max(1, pucks - 1) },
                                  plus: { store.data.settings.puckCount = min(200, pucks + 1) })
                }
                HStack {
                    Text("Call every").font(.headline).foregroundStyle(Theme.text)
                    Spacer()
                    TargetStepper(value: String(format: "%.1fs", interval), minus: { interval = max(1.5, interval - 0.5) }, plus: { interval = min(15, interval + 0.5) })
                }
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Randomize shots", isOn: $randomize.animation())
                    .font(.headline).tint(Self.lime)
                if randomize {
                    Text("Random targets and shot types from what you pick below.").font(.caption).foregroundStyle(Theme.text2)
                    zonePicker
                    typePicker
                } else {
                    Toggle("Select custom shots", isOn: $useCustom.animation())
                        .font(.headline).tint(Self.lime)
                    if useCustom {
                        customBuilder
                    } else {
                        Text("Goes through your targets in order, one shot type.").font(.caption).foregroundStyle(Theme.text2)
                        zonePicker
                        Picker("Shot", selection: $fixedType) {
                            ForEach(ShotType.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .cardStyle()

            Button { start() } label: { Label("Start calling", systemImage: "play.fill") }
                .buttonStyle(PrimaryButtonStyle(color: Self.lime))
                .disabled(!randomize && useCustom && custom.isEmpty)
        }
    }

    private var zonePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Overline("Targets")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(Zone.allCases) { z in
                    Button {
                        if zones.contains(z) { if zones.count > 1 { zones.remove(z) } } else { zones.insert(z) }
                    } label: { Chip(text: z.title, color: Self.lime, filled: zones.contains(z)) }
                        .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Overline("Shot types")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(ShotType.allCases) { t in
                    Button {
                        if types.contains(t) { if types.count > 1 { types.remove(t) } } else { types.insert(t) }
                    } label: { Chip(text: t.title, color: t.color, filled: types.contains(t)) }
                        .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private var customBuilder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Build your own list. It's called in order and repeats until you hit your shot count.")
                .font(.caption).foregroundStyle(Theme.text2)
            HStack(spacing: 8) {
                Picker("Shot", selection: $newType) { ForEach(ShotType.allCases) { Text($0.title).tag($0) } }
                Picker("Target", selection: $newZone) { ForEach(Zone.allCases) { Text($0.title).tag($0) } }
                Spacer()
                Button { custom.append(Shot(type: newType, zone: newZone)); store.haptic(.light) } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Self.lime)
                }
                .accessibilityLabel("Add shot")
            }
            .tint(Theme.text)
            if custom.isEmpty {
                Text("No shots yet. Pick a shot and a target, then tap +.").font(.footnote).foregroundStyle(Theme.text3)
            } else {
                ForEach(Array(custom.enumerated()), id: \.offset) { i, shot in
                    HStack(spacing: 10) {
                        Text("\(i + 1)").font(.number(13)).foregroundStyle(Theme.bg)
                            .frame(width: 24, height: 24).background(Circle().fill(shot.type.color))
                        Text("\(shot.type.title) · \(shot.zone.title)").foregroundStyle(Theme.text)
                        Spacer()
                        Button { var c = custom; c.remove(at: i); custom = c } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(Theme.text3)
                        }
                        .accessibilityLabel("Remove shot \(i + 1)")
                    }
                    .font(.subheadline)
                }
                Button("Clear list", role: .destructive) { custom = [] }.font(.footnote)
            }
        }
    }

    private var calling: some View {
        VStack(spacing: 14) {
            TimelineView(.periodic(from: .now, by: 0.1)) { tl in
                let elapsed = bucketStart.map { tl.date.timeIntervalSince($0) } ?? 0
                let index = bucketStart == nil ? -1 : Int(elapsed / interval)
                let phaseFrac = (elapsed / interval).truncatingRemainder(dividingBy: 1)
                let shot = index >= 0 && index < bucketSize && shotsBefore + index < calls.count ? calls[shotsBefore + index] : nil
                VStack(spacing: 10) {
                    Overline("Round \(shotsBefore / max(1, activePucks) + 1) · shot \(min(index + 1, bucketSize)) of \(bucketSize)", color: Self.lime)
                    NetView(target: shot?.zone, enabled: randomize || !useCustom ? zones : Set(calls.map(\.zone)), progress: phaseFrac)
                        .frame(height: 210)
                    Text(shot?.zone.title.uppercased() ?? "READY")
                        .font(.display(40))
                        .foregroundStyle(shot == nil ? Theme.text3 : Self.lime)
                    if let shot {
                        Chip(text: shot.type.title, color: shot.type.color, filled: true)
                    }
                }
                .frame(maxWidth: .infinity)
                .onChange(of: index) { _, new in callChanged(new) }
            }
            .cardStyle()

            HStack(spacing: 10) {
                scoreButton("Hit", hits, Theme.green, Theme.bg) { hits += 1 }
                scoreButton("Miss", misses, Theme.surface2, Theme.text) { misses += 1 }
            }
            .buttonStyle(PressableStyle())
            Text("Hit and miss are optional. Shots count either way.").font(.caption).foregroundStyle(Theme.text3)
                .frame(maxWidth: .infinity)
        }
    }

    private func scoreButton(_ label: String, _ n: Int, _ bg: Color, _ fg: Color, _ action: @escaping () -> Void) -> some View {
        Button { action(); store.haptic(.light) } label: {
            VStack(spacing: 2) {
                Text("\(n)").font(.number(28))
                Text(label).font(.caption.weight(.bold))
            }
            .frame(maxWidth: .infinity).frame(height: 76)
            .foregroundStyle(fg)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(bg))
        }
    }

    private var done: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 46)).foregroundStyle(Theme.green)
                Text("\(called) shots done").font(.display(34)).foregroundStyle(Theme.text)
                if !byType.isEmpty {
                    Text(ShotType.allCases.compactMap { t in byType[t].map { "\($0) \(t.title.lowercased())" } }.joined(separator: " · "))
                        .font(.subheadline).foregroundStyle(Theme.text2)
                }
                if hits + misses > 0 {
                    Text("\(hits) of \(hits + misses) on target").font(.subheadline).foregroundStyle(Theme.text2)
                }
                Text(lost == 0 ? "All \(pucks) pucks accounted for." : "\(lost) \(lost == 1 ? "puck" : "pucks") lost.")
                    .font(.footnote).foregroundStyle(lost == 0 ? Theme.text3 : Theme.red)
                Text("Added to today's shots.").font(.caption).foregroundStyle(Theme.text3)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            if lost > 0 {
                Button { store.data.settings.puckCount = activePucks; lost = 0 } label: {
                    Label("Update my puck count to \(activePucks)", systemImage: "pencil")
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.amber))
            }
            Button { phase = .setup } label: { Label("New session", systemImage: "arrow.counterclockwise") }
                .buttonStyle(PrimaryButtonStyle(color: Self.lime))
        }
    }

    // MARK: Flow

    private func makeCalls() -> [Shot] {
        let zoneList = Zone.allCases.filter { zones.contains($0) }
        if randomize {
            let typeList = ShotType.allCases.filter { types.contains($0) }
            var list: [Shot] = []
            for _ in 0..<goal {
                var s = Shot(type: typeList.randomElement() ?? .wrist, zone: zoneList.randomElement() ?? .topLeft)
                if zoneList.count > 1 { while s.zone == list.last?.zone { s.zone = zoneList.randomElement()! } }
                list.append(s)
            }
            return list
        }
        let pattern = useCustom ? custom : zoneList.map { Shot(type: fixedType, zone: $0) }
        guard !pattern.isEmpty else { return [] }
        return (0..<goal).map { pattern[$0 % pattern.count] }
    }

    private func start() {
        calls = makeCalls()
        guard !calls.isEmpty else { return }
        called = 0; shotsBefore = 0; byType = [:]; hits = 0; misses = 0; lost = 0; logged = false
        UIApplication.shared.isIdleTimerDisabled = true
        startBucket()
    }

    private func startBucket() {
        bucketSize = min(activePucks, remaining)
        guard bucketSize > 0 else { finish(); return }
        shotsBefore = called
        lastIndex = -1
        bucketStart = Date()
        phase = .calling
    }

    private func callChanged(_ index: Int) {
        guard index != lastIndex, index >= 0, phase == .calling else { return }
        lastIndex = index
        if index < bucketSize {
            let shot = calls[shotsBefore + index]
            called += 1
            byType[shot.type, default: 0] += 1
            if store.data.settings.sounds { AudioServicesPlaySystemSound(1057) }
            store.haptic(.medium)
        } else {
            // Bucket's empty: go pick them up.
            bucketStart = nil
            pickedUp = 0
            phase = .pickup
            store.notify(.success)
        }
    }

    private func nextBucket() {
        if remaining == 0 || activePucks == 0 { finish() } else { startBucket() }
    }

    private func finish() {
        bucketStart = nil
        logShots()
        UIApplication.shared.isIdleTimerDisabled = false
        phase = .done
    }

    /// Each shot type goes to the shot tracker separately, so it counts toward today's shot goal.
    private func logShots() {
        guard !logged else { return }
        logged = true
        for (t, n) in byType where n > 0 { store.addShots(t, n) }
        if hits > 0 { store.updateDaily { $0.onTarget += hits } }
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
