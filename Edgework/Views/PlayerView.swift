import SwiftUI
import AudioToolbox

@MainActor
final class PlayerEngine: ObservableObject {
    enum Side { case left, right }

    enum Step {
        case work(item: Int, set: Int, side: Side?)
        case rest(seconds: Int, label: String)
    }

    let workout: Workout
    let items: [WorkoutItem]
    let steps: [Step]
    unowned let store: Store

    @Published var index = 0
    @Published var now = Date()
    @Published var paused = false
    @Published var started = false
    @Published var finished = false
    @Published private(set) var stepDuration: TimeInterval = 0

    private var stepEnd: Date?
    private var pausedRemaining: TimeInterval?
    private var pausedAt: Date?
    private var pausedTotal: TimeInterval = 0
    private var startDate = Date()
    private var lastBeep = -1
    private var timer: Timer?
    private(set) var completed: [UUID: Int] = [:]

    init(workout: Workout, store: Store) {
        self.workout = workout
        self.store = store
        let items = workout.ordered
        self.items = items
        var steps: [Step] = []
        for (i, item) in items.enumerated() {
            guard let ex = item.exercise else { continue }
            let isLastItem = i == items.count - 1
            for s in 1...max(1, item.sets) {
                if ex.measure == .seconds && ex.perSide {
                    steps.append(.work(item: i, set: s, side: .left))
                    steps.append(.rest(seconds: 5, label: "Switch sides"))
                    steps.append(.work(item: i, set: s, side: .right))
                } else {
                    steps.append(.work(item: i, set: s, side: nil))
                }
                let isLast = isLastItem && s == item.sets
                if !isLast && item.rest > 0 {
                    steps.append(.rest(seconds: item.rest, label: s == item.sets ? "Next exercise" : "Rest"))
                }
            }
        }
        self.steps = steps
    }

    // MARK: Derived

    var step: Step? { steps.indices.contains(index) ? steps[index] : nil }

    var progress: Double { steps.isEmpty ? 1 : Double(index) / Double(steps.count) }

    var elapsed: Int {
        let end = finished ? (pausedAt ?? now) : now
        let pausing = paused ? end.timeIntervalSince(pausedAt ?? end) : 0
        return max(0, Int(end.timeIntervalSince(startDate) - pausedTotal - pausing))
    }

    var remaining: TimeInterval {
        if let r = pausedRemaining { return r }
        guard let end = stepEnd else { return 0 }
        return max(0, end.timeIntervalSince(now))
    }

    var stepProgress: Double { stepDuration > 0 ? 1 - remaining / stepDuration : 0 }

    func item(_ i: Int) -> WorkoutItem { items[i] }

    func isTimed(_ step: Step) -> Bool {
        switch step {
        case .rest: return true
        case .work(let i, _, _): return items[i].exercise?.measure == .seconds
        }
    }

    /// Next work step after the current index.
    var nextWork: (item: WorkoutItem, set: Int)? {
        var j = index + 1
        while steps.indices.contains(j) {
            if case .work(let i, let s, _) = steps[j] { return (items[i], s) }
            j += 1
        }
        return nil
    }

    var exerciseNumber: Int {
        if case .work(let i, _, _)? = step { return i + 1 }
        return min(items.count, (nextWork.map { w in items.firstIndex { $0.id == w.item.id } ?? 0 } ?? 0) + 1)
    }

    // MARK: Control

    func start() {
        started = true
        startDate = Date()
        now = Date()
        enterStep()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func enterStep() {
        lastBeep = -1
        pausedRemaining = nil
        guard let step else { return }
        if isTimed(step) {
            let secs: Int
            switch step {
            case .rest(let s, _): secs = s
            case .work(let i, _, _): secs = store.target(items[i])
            }
            stepDuration = TimeInterval(secs)
            stepEnd = Date().addingTimeInterval(stepDuration)
            if paused { pausedRemaining = stepDuration }
        } else {
            stepDuration = 0
            stepEnd = nil
        }
    }

    private func tick() {
        now = Date()
        guard started, !paused, !finished, let end = stepEnd else { return }
        let left = end.timeIntervalSince(now)
        let whole = Int(ceil(left))
        if store.data.settings.countdown && whole <= 3 && whole > 0 && whole != lastBeep {
            lastBeep = whole
            if store.data.settings.sounds { AudioServicesPlaySystemSound(1104) }
            store.haptic(.soft)
        }
        if left <= 0 {
            if case .rest? = step, !store.data.settings.autoAdvance {
                stepEnd = nil
                store.notify(.warning)
                return
            }
            complete(counted: true)
        }
    }

    /// Finish the current step. Work steps add to the completed set count.
    func complete(counted: Bool) {
        guard let step else { return }
        if case .work(let i, _, let side) = step, counted, side != .left {
            completed[items[i].id, default: 0] += 1
        }
        if case .work = step {
            store.notify(.success)
            if store.data.settings.sounds { AudioServicesPlaySystemSound(1057) }
        } else {
            store.haptic(.heavy)
        }
        advance()
    }

    private func advance() {
        if index + 1 >= steps.count {
            finish()
        } else {
            index += 1
            enterStep()
        }
    }

    func back() {
        guard index > 0 else { return }
        index -= 1
        if case .work(let i, _, let side) = steps[index], side != .left, let c = completed[items[i].id], c > 0 {
            completed[items[i].id] = c - 1
        }
        enterStep()
    }

    func skipExercise() {
        guard case .work(let i, _, _)? = step else { return complete(counted: false) }
        var j = index
        while steps.indices.contains(j + 1) {
            if case .work(let k, _, _) = steps[j + 1], k != i { break }
            j += 1
        }
        index = j
        advance()
    }

    func addRest(_ seconds: TimeInterval) {
        if let r = pausedRemaining { pausedRemaining = r + seconds }
        stepEnd = stepEnd?.addingTimeInterval(seconds)
        stepDuration += seconds
    }

    func togglePause() {
        if paused {
            if let r = pausedRemaining, stepEnd != nil { stepEnd = Date().addingTimeInterval(r) }
            if let p = pausedAt { pausedTotal += Date().timeIntervalSince(p) }
            pausedRemaining = nil
            pausedAt = nil
            paused = false
        } else {
            pausedRemaining = stepEnd != nil ? remaining : nil
            pausedAt = Date()
            paused = true
        }
        store.haptic(.medium)
    }

    func finish() {
        pausedAt = Date()
        finished = true
        stop()
        store.notify(.success)
    }

    func record(rpe: Int, feeling: Feeling, note: String) -> SessionRecord {
        let entries: [SessionEntry] = items.compactMap { item in
            guard let ex = item.exercise, let sets = completed[item.id], sets > 0 else { return nil }
            return SessionEntry(exerciseID: ex.id, sets: sets, value: store.target(item), measure: ex.measure)
        }
        return SessionRecord(date: Date(), title: workout.title, focus: workout.focus, duration: elapsed,
                             entries: entries, rpe: rpe, feeling: feeling, note: note)
    }
}

struct PlayerView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine: PlayerEngine
    @State private var confirmExit = false

    init(workout: Workout, store: Store) {
        _engine = StateObject(wrappedValue: PlayerEngine(workout: workout, store: store))
    }

    private var accent: Color {
        guard let step = engine.step else { return engine.workout.focus.color }
        switch step {
        case .rest: return Theme.green
        case .work(let i, _, _): return engine.item(i).exercise?.category.color ?? Theme.ice
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.22), .clear], center: .top, startRadius: 10, endRadius: 520)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: engine.index)

            if engine.finished {
                SummaryView(engine: engine) { dismiss() }
            } else {
                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 12)
                    if !engine.started {
                        readyView
                    } else if let step = engine.step {
                        switch step {
                        case .work(let i, let s, let side): workView(engine.item(i), set: s, side: side)
                        case .rest(_, let label): restView(label)
                        }
                    }
                    Spacer(minLength: 12)
                    controls
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .onDisappear { engine.stop() }
        .confirmationDialog("End workout?", isPresented: $confirmExit, titleVisibility: .visible) {
            Button("Finish & log what I did") { engine.finish() }
            Button("Discard workout", role: .destructive) { engine.stop(); dismiss() }
            Button("Keep going", role: .cancel) {}
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                RoundIconButton(symbol: "xmark", size: 36) {
                    if engine.started { confirmExit = true } else { dismiss() }
                }
                Spacer()
                VStack(spacing: 1) {
                    Text(engine.workout.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.text2).lineLimit(1)
                    Text(engine.elapsed.clock).font(.number(15)).foregroundStyle(Theme.text)
                }
                Spacer()
                RoundIconButton(symbol: engine.paused ? "play.fill" : "pause.fill", size: 36) { engine.togglePause() }
                    .opacity(engine.started ? 1 : 0)
                    .disabled(!engine.started)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(accent)
                        .frame(width: max(6, geo.size.width * engine.progress))
                        .animation(.easeOut(duration: 0.3), value: engine.index)
                }
            }
            .frame(height: 5)
            HStack {
                Text("Exercise \(engine.exerciseNumber) of \(engine.items.count)")
                Spacer()
                Text("\(Int(engine.progress * 100))%")
            }
            .font(.number(12, .semibold))
            .foregroundStyle(Theme.text3)
        }
        .padding(.top, 8)
    }

    private var readyView: some View {
        VStack(spacing: 18) {
            IconBadge(symbol: engine.workout.focus.symbol, color: engine.workout.focus.color, size: 84)
            Text(engine.workout.title).font(.display(38)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
            Text("\(engine.items.count) exercises · \(engine.workout.totalSets) sets · ~\(store.estimateMinutes(engine.workout)) min")
                .font(.subheadline).foregroundStyle(Theme.text2)
            if let first = engine.items.first, let ex = first.exercise {
                VStack(spacing: 4) {
                    Overline("First up")
                    Text(ex.name).font(.headline).foregroundStyle(Theme.text)
                }
                .padding(.top, 10)
            }
        }
    }

    private func workView(_ item: WorkoutItem, set: Int, side: PlayerEngine.Side?) -> some View {
        let ex = item.exercise!
        let color = ex.category.color
        let timed = ex.measure == .seconds
        return VStack(spacing: 16) {
            VStack(spacing: 8) {
                Overline("\(item.block.title) · Set \(set) of \(item.sets)", color: color)
                Text(ex.name)
                    .font(.display(36))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let side {
                    Chip(text: side == .left ? "Left side" : "Right side", symbol: "arrow.left.and.right", color: color)
                } else if ex.perSide {
                    Chip(text: "Each side", symbol: "arrow.left.and.right", color: color)
                }
            }

            if timed {
                HStack(spacing: 12) {
                    FigureView(exercise: ex, animate: !engine.paused)
                        .frame(width: 150, height: 150)
                    ZStack {
                        Ring(progress: engine.stepProgress, color: color, lineWidth: 12)
                            .animation(.linear(duration: 0.1), value: engine.stepProgress)
                        VStack(spacing: 0) {
                            Text("\(Int(ceil(engine.remaining)))")
                                .font(.number(54, .heavy)).foregroundStyle(Theme.text)
                                .contentTransition(.numericText(countsDown: true))
                            Text(engine.paused ? "paused" : "seconds").font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
                        }
                    }
                    .frame(width: 150, height: 150)
                }
            } else {
                VStack(spacing: 4) {
                    FigureView(exercise: ex, animate: !engine.paused)
                        .frame(height: 170)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(ex.measure == .meters ? ex.measure.format(store.target(item)) : "\(store.target(item))")
                            .font(.number(72, .heavy)).foregroundStyle(Theme.text)
                            .contentTransition(.numericText())
                        if ex.measure == .reps {
                            Text(ex.measure.label(store.target(item))).font(.title3.weight(.semibold)).foregroundStyle(Theme.text2)
                        }
                    }
                }
            }

            setDots(item: item, current: set, color: color)

            if let cue = ex.cues.first {
                Text(cue).font(.subheadline).foregroundStyle(Theme.text2).multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Button { withAnimation { store.adjust(item, up: false) } } label: {
                    Label("Easier", systemImage: "minus")
                }
                .buttonStyle(MiniPillStyle(color: Theme.ice))
                Button { withAnimation { store.adjust(item, up: true) } } label: {
                    Label("Harder", systemImage: "plus")
                }
                .buttonStyle(MiniPillStyle(color: Theme.amber))
            }
            .disabled(item.fixed)
            .opacity(item.fixed ? 0.3 : 1)
        }
    }

    private func setDots(item: WorkoutItem, current: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            ForEach(1...max(1, item.sets), id: \.self) { s in
                Capsule()
                    .fill(s < current ? color : (s == current ? color.opacity(0.6) : Color.white.opacity(0.1)))
                    .frame(width: s == current ? 22 : 10, height: 6)
            }
        }
        .animation(.snappy, value: current)
    }

    private func restView(_ label: String) -> some View {
        VStack(spacing: 22) {
            Overline(label, color: Theme.green)
            ZStack {
                Ring(progress: 1 - engine.stepProgress, color: Theme.green, lineWidth: 14)
                    .animation(.linear(duration: 0.1), value: engine.stepProgress)
                VStack(spacing: 2) {
                    Text(Int(ceil(engine.remaining)).clock)
                        .font(.number(64, .heavy)).foregroundStyle(Theme.text)
                    Text(engine.paused ? "paused" : "breathe").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text2)
                }
            }
            .frame(width: 210, height: 210)

            HStack(spacing: 10) {
                Button { engine.addRest(15) } label: { Label("15s", systemImage: "plus") }
                    .buttonStyle(MiniPillStyle(color: Theme.text))
                Button { engine.complete(counted: false) } label: { Label("Skip rest", systemImage: "forward.fill") }
                    .buttonStyle(MiniPillStyle(color: Theme.green))
            }

            if let next = engine.nextWork, let ex = next.item.exercise {
                HStack(spacing: 12) {
                    IconBadge(symbol: ex.symbol, color: ex.category.color, size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Overline("Up next · set \(next.set) of \(next.item.sets)")
                        Text(ex.name).font(.headline).foregroundStyle(Theme.text)
                    }
                    Spacer()
                    Text(store.targetText(next.item)).font(.number(20)).foregroundStyle(Theme.text)
                }
                .cardStyle(padding: 14)
            }
        }
    }

    private var controls: some View {
        Group {
            if !engine.started {
                Button { engine.start() } label: { Label("Let's go", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle(color: engine.workout.focus.color))
            } else if let step = engine.step {
                HStack(spacing: 10) {
                    RoundIconButton(symbol: "backward.end.fill", size: 54) { engine.back() }
                        .disabled(engine.index == 0)
                        .opacity(engine.index == 0 ? 0.4 : 1)
                    switch step {
                    case .work(let i, _, _):
                        if engine.isTimed(step) {
                            Button { engine.complete(counted: true) } label: { Label("Done early", systemImage: "checkmark") }
                                .buttonStyle(PrimaryButtonStyle(color: accent))
                        } else {
                            Button { engine.complete(counted: true) } label: {
                                Label("Done · \(store.targetText(engine.item(i)))", systemImage: "checkmark")
                            }
                            .buttonStyle(PrimaryButtonStyle(color: accent))
                        }
                    case .rest:
                        Button { engine.complete(counted: false) } label: { Label("Ready", systemImage: "bolt.fill") }
                            .buttonStyle(PrimaryButtonStyle(color: Theme.green))
                    }
                    Menu {
                        Button { engine.skipExercise() } label: { Label("Skip this exercise", systemImage: "forward.end.fill") }
                        Button { engine.finish() } label: { Label("Finish now", systemImage: "flag.checkered") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Theme.surface2))
                    }
                }
            }
        }
    }
}

struct MiniPillStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(Capsule().fill(color.opacity(0.14)))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
