import SwiftUI
import UIKit

enum Day {
    static let cal = Calendar.current

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(_ date: Date) -> String { keyFormatter.string(from: date) }

    static func parse(_ key: String) -> Date? { keyFormatter.date(from: key) }

    static func seed(_ date: Date) -> Int {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    static func add(_ days: Int, to date: Date) -> Date { cal.date(byAdding: .day, value: days, to: date) ?? date }

    static func start(_ date: Date) -> Date { cal.startOfDay(for: date) }

    /// Monday-first dates for the week containing `date`.
    static func week(of date: Date) -> [Date] {
        let wd = cal.component(.weekday, from: date) // 1 = Sunday
        let offset = (wd + 5) % 7
        let monday = add(-offset, to: start(date))
        return (0..<7).map { add($0, to: monday) }
    }

    /// Calendar weekday numbers in Monday-first order.
    static let mondayFirst = [2, 3, 4, 5, 6, 7, 1]
    static let shortNames = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
}

@MainActor
final class Store: ObservableObject {
    @Published var data: AppData {
        didSet { scheduleSave() }
    }
    @Published var activeWorkout: Workout?

    private var pendingSave: Task<Void, Never>?
    private let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("edgework.json")
    }()

    init() {
        if let raw = try? Data(contentsOf: url), let decoded = try? JSONDecoder.edgework.decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
        if UserDefaults.standard.bool(forKey: "demoData") { seedDemo() }
        ensureToday()
    }

    /// Fills the app with a month of fake history. Only used via the `-demoData YES` launch argument.
    private func seedDemo() {
        var d = AppData()
        d.onboarded = true
        d.settings.name = "Alex"
        let today = Day.start(Date())
        var rng = SeededRNG(seed: 42)
        data = d
        for back in stride(from: 34, through: 1, by: -1) where Int.random(in: 0..<10, using: &rng) < 7 {
            let date = Day.add(-back, to: today).addingTimeInterval(17.5 * 3600)
            let w = preview(for: date)
            let entries = w.items.compactMap { item -> SessionEntry? in
                guard let ex = item.exercise else { return nil }
                return SessionEntry(exerciseID: ex.id, sets: item.sets, value: item.base, measure: ex.measure)
            }
            d.sessions.insert(SessionRecord(date: date, title: w.title, focus: w.focus, duration: estimateMinutes(w) * 60 + Int.random(in: -120...240, using: &rng),
                                            entries: entries, rpe: Int.random(in: 5...8, using: &rng), feeling: .right, note: ""), at: 0)
        }
        let tests: [(Benchmark, [Double])] = [(.vertical, [21.5, 22.0, 23.5, 24.0]), (.sprint30, [4.62, 4.55, 4.49, 4.41]), (.plank, [90, 105, 120, 140]), (.broadJump, [88, 90, 93])]
        for (b, values) in tests {
            for (i, v) in values.enumerated() {
                d.benchmarks.append(BenchmarkEntry(benchmark: b, date: Day.add(-28 + i * 9, to: today), value: v))
            }
        }
        d.factors = ["push-up": 0.85, "skater-bound": 1.2]
        let evening: (Int) -> Date = { Day.add($0, to: today).addingTimeInterval(19 * 3600) }
        d.events = [
            CalEvent(id: "demo-1", title: "Practice", start: evening(1), allDay: false, location: "Main Rink", guessed: .practice),
            CalEvent(id: "demo-2", title: "Game vs Hawks", start: evening(3), allDay: false, location: "Main Rink", guessed: .game),
            CalEvent(id: "demo-3", title: "Team photos", start: evening(4), allDay: false, location: "", guessed: .ignore),
            CalEvent(id: "demo-4", title: "Tournament: Wolves @ Bears", start: evening(6), allDay: false, location: "", guessed: .game),
        ]
        d.favorites = ["skater-bound", "copenhagen-plank"]
        d.settings.trainTimes = ["2": 17 * 60, "3": 17 * 60, "4": 18 * 60, "6": 16 * 60, String(Day.cal.component(.weekday, from: today)): 17 * 60 + 30]
        var log = DailyLog()
        log.shots = ["wrist": 50, "snap": 15, "backhand": 10]
        log.onTarget = 48
        log.stickMinutes = 10
        log.water = 5
        log.sleep = 7.5
        log.soreness = 2
        log.energy = 4
        log.runKm = 3.2
        d.daily[Day.key(today)] = log
        for (i, back) in [12, 9, 6, 3, 1].enumerated() {
            var w = DailyLog()
            w.weightKg = 72.5 - Double(i) * 0.3
            w.runKm = back == 1 ? 2.5 : 0
            d.daily[Day.key(Day.add(-back, to: today))] = w
        }
        let eaten: [(String, Double, Meal)] = [("oats-pb-banana", 1, .breakfast), ("oj", 1, .breakfast), ("turkey-sandwich", 1, .lunch),
                                               ("apple", 1, .lunch), ("pbj", 1, .preGame), ("choc-milk", 2, .postWorkout)]
        for (id, servings, meal) in eaten {
            if let f = FoodDB.byID[id] { d.foods.append(FoodEntry(food: f, servings: servings, meal: meal, date: today.addingTimeInterval(9 * 3600))) }
        }
        data = d
        addMustDoPreset(1)
        addMustDoPreset(0)
    }

    // MARK: Persistence

    private func scheduleSave() {
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        guard let raw = try? JSONEncoder.edgework.encode(data) else { return }
        try? raw.write(to: url, options: .atomic)
    }

    func importBackup(_ raw: Data) -> Bool {
        guard let decoded = try? JSONDecoder.edgework.decode(AppData.self, from: raw) else { return false }
        data = decoded
        ensureToday()
        saveNow()
        return true
    }

    func resetAll() {
        data = AppData()
        ensureToday()
        saveNow()
    }

    // MARK: Scaling

    var intensity: Double { data.settings.intensity }

    func factor(_ id: String) -> Double { data.factors[id] ?? 1 }

    func target(_ item: WorkoutItem) -> Int {
        guard let ex = item.exercise else { return item.base }
        if item.fixed { return item.base }
        if usesLines(item.exerciseID) {
            return Measure.lines.round(Double(data.settings.lineCount) * intensity * factor(item.exerciseID) * todayScale)
        }
        return ex.measure.round(Double(item.base) * intensity * factor(item.exerciseID) * todayScale)
    }

    /// Travelling moves (high knees, carioca, side lunges…) can be counted line-to-line instead of time or reps.
    func usesLines(_ id: String) -> Bool {
        guard Library.travelIDs.contains(id) else { return false }
        if let m = data.settings.measureModes[id] { return m == "lines" }
        return data.settings.lineMode
    }

    func measure(_ item: WorkoutItem) -> Measure {
        item.fixed ? (item.exercise?.measure ?? .reps) : measure(of: item.exerciseID)
    }

    func measure(of id: String) -> Measure {
        usesLines(id) ? .lines : (Library.byID[id]?.measure ?? .reps)
    }

    func setLineMode(_ id: String, _ lines: Bool?) {
        data.settings.measureModes[id] = lines.map { $0 ? "lines" : "default" }
    }

    func targetText(_ item: WorkoutItem) -> String {
        guard let ex = item.exercise else { return "" }
        return measure(item).format(target(item))
    }

    /// Nudges one exercise's personal multiplier until its shown target actually changes.
    func adjust(_ item: WorkoutItem, up: Bool) {
        guard !item.fixed else { return }
        let before = target(item)
        var f = factor(item.exerciseID)
        for _ in 0..<20 {
            f = (f + (up ? 0.05 : -0.05)).clamped(0.25, 3.0)
            data.factors[item.exerciseID] = f
            if target(item) != before || f <= 0.25 || f >= 3.0 { break }
        }
        if abs(f - 1) < 0.001 { data.factors[item.exerciseID] = nil }
        haptic(.light)
    }

    func resetFactor(_ id: String) { data.factors[id] = nil }

    func adjustAll(up: Bool) {
        data.settings.intensity = ((intensity + (up ? 0.05 : -0.05)) * 100).rounded() / 100
        data.settings.intensity = data.settings.intensity.clamped(0.4, 2.0)
        haptic(.light)
    }

    // MARK: Schedule

    func kind(_ e: CalEvent) -> EventKind { data.eventKinds[e.id] ?? e.guessed }

    /// Games and practices from the imported calendar on a given day.
    func events(on date: Date) -> [CalEvent] {
        let k = Day.key(date)
        return data.events.filter { Day.key($0.start) == k && kind($0) != .ignore }.sorted { $0.start < $1.start }
    }

    var upcomingEvents: [CalEvent] {
        let now = Date().addingTimeInterval(-3 * 3600)
        return data.events.filter { $0.start >= now && kind($0) != .ignore }.sorted { $0.start < $1.start }
    }

    func scheduledType(for date: Date) -> DayType {
        let today = events(on: date)
        if today.contains(where: { kind($0) == .game }) { return .game }
        let wd = Day.cal.component(.weekday, from: date)
        if today.isEmpty && data.settings.gameDays.contains(wd) { return .game }
        let yesterday = Day.add(-1, to: date)
        let ywd = Day.cal.component(.weekday, from: yesterday)
        let yOverride = data.dayOverrides[Day.key(yesterday)]
        if yOverride == .game || events(on: yesterday).contains(where: { kind($0) == .game })
            || (yOverride == nil && data.settings.gameDays.contains(ywd)) {
            return .postGame
        }
        if !today.isEmpty || data.settings.practiceDays.contains(wd) { return .practice }
        return .off
    }

    func dayType(for date: Date) -> DayType {
        data.dayOverrides[Day.key(date)] ?? scheduledType(for: date)
    }

    func setDayType(_ type: DayType?, for date: Date) {
        data.dayOverrides[Day.key(date)] = type
        if Day.key(date) == Day.key(Date()), data.today?.focus == nil {
            rebuildToday(seed: data.today?.seed ?? Day.seed(date), focus: nil, duration: defaultDuration(for: date))
        }
    }

    /// The focuses the auto-picker rotates through, given style and settings.
    var focusRotation: [Focus] {
        let st = data.settings
        var r = st.style.rotation
        if st.runDays && !r.contains(.run) { r.insert(.run, at: min(3, r.count)) }
        if !st.runDays { r.removeAll { $0 == .run } }
        if !st.includeHockey { r.removeAll { $0 == .hands } }
        if st.position == .goalie && st.style != .general && !r.contains(.goalie) { r.insert(.goalie, at: min(2, r.count)) }
        if st.lowImpact { r.removeAll { $0 == .power || $0 == .hiit } }
        return r.isEmpty ? [.fullBody] : r
    }

    /// Focuses ordered by how long it's been since you trained them (longest first).
    func rankedFocuses(before date: Date) -> [Focus] {
        let start = Day.start(date)
        let past = data.sessions.filter { $0.date < start }
        let rotation = focusRotation
        let offset = Day.seed(date) % max(1, rotation.count)
        let scored = rotation.enumerated().map { pair -> (Focus, Double) in
            let (i, f) = pair
            let last = past.filter { $0.focus == f }.map(\.date).max()
            let days = last.map { start.timeIntervalSince(Day.start($0)) / 86_400 } ?? 30
            let tiebreak = Double((i + rotation.count - offset) % rotation.count) * 0.01
            return (f, days - tiebreak)
        }
        return scored.sorted { $0.1 > $1.1 }.map(\.0)
    }

    func autoFocus(for date: Date) -> Focus {
        switch dayType(for: date) {
        case .game: return .activation
        case .postGame: return .recovery
        case .practice:
            let options: [Focus] = data.settings.style == .general ? [.abs, .upper, .mobility] : [.core, .mobility, .upper]
            return options[Day.seed(date) % options.count]
        case .off:
            let today = Day.start(Date())
            let ahead = max(0, Day.cal.dateComponents([.day], from: today, to: Day.start(date)).day ?? 0)
            let ranked = rankedFocuses(before: ahead == 0 ? date : today)
            return ranked[ahead % ranked.count]
        }
    }

    func defaultDuration(for date: Date) -> Int {
        switch dayType(for: date) {
        case .game: return min(20, data.settings.duration)
        case .postGame: return min(25, data.settings.duration)
        default: return data.settings.duration
        }
    }

    // MARK: Generation

    func generate(focus: Focus, minutes: Int, seed: Int) -> Workout {
        Generator.make(focus: focus, minutes: minutes, seed: UInt64(max(0, seed)), settings: data.settings)
    }

    func preview(for date: Date) -> Workout {
        generate(focus: autoFocus(for: date), minutes: defaultDuration(for: date), seed: Day.seed(date))
    }

    func ensureToday() {
        let now = Date()
        if data.today?.dateKey != Day.key(now) {
            rebuildToday(seed: Day.seed(now), focus: nil, duration: defaultDuration(for: now))
        }
    }

    func rebuildToday(seed: Int, focus: Focus?, duration: Int) {
        let now = Date()
        let f = focus ?? autoFocus(for: now)
        data.today = TodayState(dateKey: Day.key(now), seed: seed, focus: focus, duration: duration,
                                workout: generate(focus: f, minutes: duration, seed: seed))
    }

    func reroll() {
        guard let t = data.today else { return ensureToday() }
        rebuildToday(seed: t.seed + 1, focus: t.focus, duration: t.duration)
        haptic(.medium)
    }

    func setTodayFocus(_ focus: Focus?) {
        guard let t = data.today else { return }
        rebuildToday(seed: t.seed, focus: focus, duration: t.duration)
    }

    func setTodayDuration(_ minutes: Int) {
        guard let t = data.today else { return }
        rebuildToday(seed: t.seed, focus: t.focus, duration: minutes)
    }

    var todayWorkout: Binding<Workout> {
        Binding(get: { self.data.today?.workout ?? .empty },
                set: { self.data.today?.workout = $0 })
    }

    // MARK: Estimates

    func estimateSeconds(_ item: WorkoutItem) -> Int {
        guard let ex = item.exercise else { return 0 }
        return Generator.seconds(sets: item.sets, value: target(item), measure: measure(item), perSide: ex.perSide, rest: item.rest)
    }

    func estimateMinutes(_ w: Workout) -> Int {
        max(1, Int((Double(w.items.map(estimateSeconds).reduce(0, +)) / 60).rounded()))
    }

    // MARK: Sessions

    func start(_ workout: Workout) {
        guard !workout.items.isEmpty else { return }
        activeWorkout = workout
    }

    func log(_ record: SessionRecord) {
        data.sessions.append(record)
        data.sessions.sort { $0.date > $1.date }
        creditDaily(from: record)
        Notifier.reschedule(self)
        switch record.feeling {
        case .easy: adjustAll(up: true)
        case .hard: adjustAll(up: false)
        case .right: break
        }
    }

    func deleteSession(_ id: UUID) {
        data.sessions.removeAll { $0.id == id }
    }

    var activeDays: Set<String> { Set(data.sessions.map { Day.key($0.date) }) }

    var currentStreak: Int {
        let days = activeDays
        var date = Date()
        if !days.contains(Day.key(date)) { date = Day.add(-1, to: date) }
        var n = 0
        while days.contains(Day.key(date)) {
            n += 1
            date = Day.add(-1, to: date)
        }
        return n
    }

    var bestStreak: Int {
        let dates = activeDays.compactMap { key -> Date? in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: key)
        }.sorted()
        var best = 0, run = 0
        var prev: Date?
        for d in dates {
            if let p = prev, Day.cal.dateComponents([.day], from: p, to: d).day == 1 { run += 1 } else { run = 1 }
            best = max(best, run)
            prev = d
        }
        return best
    }

    func sessions(inLast days: Int) -> [SessionRecord] {
        let cutoff = Day.add(-(days - 1), to: Day.start(Date()))
        return data.sessions.filter { $0.date >= cutoff }
    }

    func sessions(on date: Date) -> [SessionRecord] {
        let k = Day.key(date)
        return data.sessions.filter { Day.key($0.date) == k }
    }

    var weekSessions: [SessionRecord] {
        let monday = Day.week(of: Date())[0]
        return data.sessions.filter { $0.date >= monday }
    }

    func timesPerformed(_ id: String) -> (count: Int, last: Date?) {
        let hits = data.sessions.filter { $0.entries.contains { $0.exerciseID == id } }
        return (hits.count, hits.map(\.date).max())
    }

    /// Sets per muscle over the last N days, primary counts 1, secondary 0.5.
    func muscleVolume(days: Int) -> [Muscle: Double] {
        var v: [Muscle: Double] = [:]
        for s in sessions(inLast: days) {
            for e in s.entries {
                guard let ex = Library.byID[e.exerciseID] else { continue }
                for m in ex.primary { v[m, default: 0] += Double(e.sets) }
                for m in ex.secondary { v[m, default: 0] += Double(e.sets) * 0.5 }
            }
        }
        return v
    }

    // MARK: Favorites & custom

    func isFavorite(_ id: String) -> Bool { data.favorites.contains(id) }

    func toggleFavorite(_ id: String) {
        if data.favorites.contains(id) { data.favorites.remove(id) } else { data.favorites.insert(id) }
        haptic(.light)
    }

    func saveCustom(_ w: Workout) {
        if let i = data.custom.firstIndex(where: { $0.id == w.id }) {
            data.custom[i] = w
        } else {
            data.custom.append(w)
        }
    }

    func add(_ exercise: Exercise, to workoutID: UUID) {
        guard let i = data.custom.firstIndex(where: { $0.id == workoutID }) else { return }
        data.custom[i].items.append(item(for: exercise, block: exercise.category == .warmup ? .warmup : .main))
    }

    func item(for ex: Exercise, block: Block) -> WorkoutItem {
        let rest = block == .main || block == .finisher ? Int((Double(ex.category.defaultRest) * data.settings.rest.multiplier).rounded()) : 5
        return WorkoutItem(exerciseID: ex.id, sets: ex.sets, base: ex.base, rest: rest, block: block)
    }

    // MARK: Benchmarks

    func entries(_ b: Benchmark) -> [BenchmarkEntry] {
        data.benchmarks.filter { $0.benchmark == b }.sorted { $0.date < $1.date }
    }

    func best(_ b: Benchmark) -> Double? {
        let values = entries(b).map(\.value)
        return b.lowerIsBetter ? values.min() : values.max()
    }

    // MARK: Feedback

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard data.settings.haptics else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard data.settings.haptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

extension JSONEncoder {
    static var edgework: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

extension JSONDecoder {
    static var edgework: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension Comparable {
    func clamped(_ lo: Self, _ hi: Self) -> Self { min(max(self, lo), hi) }
}
