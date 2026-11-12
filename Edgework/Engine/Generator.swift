import Foundation

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x2545F4914F6CDD1D &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private struct FocusPlan {
    var main: [(Category, Double)]
    var finisher: [Category]
    var warmups: Int
    var cooldowns: Int
    var minMain: Int
    var maxMain: Int
    var setsOverride: Int? = nil
    var volume: Double = 1
    var maxMinutes: Int? = nil
}

enum Generator {
    /// Rough duration estimate for one item, in seconds.
    static func seconds(sets: Int, value: Int, measure: Measure, perSide: Bool, rest: Int) -> Int {
        let sides = perSide ? 2 : 1
        let work: Int
        switch measure {
        case .reps: work = value * 3 * sides
        case .seconds: work = value * sides + (perSide ? 5 : 0)
        case .meters: work = (value / 4 + 4) * sides
        }
        return sets * (work + 8) + max(0, sets - 1) * rest + 10
    }

    static func make(focus: Focus, minutes: Int, seed: UInt64, settings: Settings) -> Workout {
        var rng = SeededRNG(seed: seed &+ UInt64(Focus.allCases.firstIndex(of: focus) ?? 0) &* 104_729)
        var plan = plan(for: focus)
        tune(&plan, for: settings.position, focus: focus)
        let minutes = min(minutes, plan.maxMinutes ?? minutes)

        let available = Library.all.filter { ex in
            ex.equipment.allSatisfy { settings.equipment.contains($0) }
                && (ex.category != .goalie || settings.position == .goalie || focus == .goalie)
        }
        func pool(_ cat: Category) -> [Exercise] { available.filter { $0.category == cat } }

        var used = Set<String>()
        var items: [WorkoutItem] = []

        func makeItem(_ ex: Exercise, _ block: Block) -> WorkoutItem {
            let isWork = block == .main || block == .finisher
            var sets = ex.sets
            var volume = 1.0
            if isWork {
                sets = max(1, ex.sets + settings.phase.setsDelta)
                volume = settings.phase.volume * plan.volume
                if let o = plan.setsOverride { sets = min(sets, o) }
            }
            let base = ex.measure.round(Double(ex.base) * volume)
            let rest = isWork ? Int((Double(ex.category.defaultRest) * settings.rest.multiplier).rounded()) : 5
            return WorkoutItem(exerciseID: ex.id, sets: sets, base: base, rest: rest, block: block)
        }
        func cost(_ item: WorkoutItem) -> Int {
            guard let ex = item.exercise else { return 0 }
            return seconds(sets: item.sets, value: item.base, measure: ex.measure, perSide: ex.perSide, rest: item.rest)
        }
        func take(_ n: Int, from candidates: [Exercise], block: Block) -> [WorkoutItem] {
            var c = candidates.filter { !used.contains($0.id) }
            c.shuffle(using: &rng)
            let picked = Array(c.prefix(n))
            picked.forEach { used.insert($0.id) }
            return picked.map { makeItem($0, block) }
        }

        // Warm-up
        let warm = take(plan.warmups, from: pool(.warmup), block: .warmup)
        items += warm

        // Cool-down (picked now so the budget is known)
        let coolPool = available.filter { $0.category == .mobility && $0.tags.contains(.cooldown) }
        let cool = take(plan.cooldowns, from: coolPool, block: .cooldown)

        var budget = minutes * 60 - warm.map(cost).reduce(0, +) - cool.map(cost).reduce(0, +)
        if !plan.finisher.isEmpty { budget -= 200 }

        // Main
        var weights = plan.main
        var main: [WorkoutItem] = []
        var lastCategory: Category?
        var guardCount = 0
        while main.count < plan.maxMain && !weights.isEmpty && guardCount < 200 {
            guardCount += 1
            let total = weights.reduce(0) { $0 + $1.1 }
            var roll = Double.random(in: 0..<total, using: &rng)
            var cat = weights[0].0
            for (c, w) in weights {
                if roll < w { cat = c; break }
                roll -= w
            }
            // Spread categories out instead of stacking the same one back to back.
            if cat == lastCategory && weights.count > 1 && Double.random(in: 0..<1, using: &rng) < 0.5 { continue }
            let candidates = pool(cat).filter { !used.contains($0.id) }
            guard let ex = candidates.randomElement(using: &rng) else {
                weights.removeAll { $0.0 == cat }
                continue
            }
            let item = makeItem(ex, .main)
            let c = cost(item)
            if main.count >= plan.minMain && c > budget { break }
            budget -= c
            used.insert(ex.id)
            main.append(item)
            lastCategory = cat
        }
        main.sort { ($0.exercise?.category.sessionRank ?? 0) < ($1.exercise?.category.sessionRank ?? 0) }
        items += main

        // Finisher
        if let fCat = plan.finisher.randomElement(using: &rng) {
            items += take(1, from: pool(fCat), block: .finisher)
        }
        items += cool

        return Workout(title: focus.title, subtitle: focus.tagline, focus: focus, items: items)
    }

    private static func plan(for focus: Focus) -> FocusPlan {
        switch focus {
        case .activation:
            return FocusPlan(main: [(.power, 0.4), (.speed, 0.4), (.balance, 0.2)], finisher: [], warmups: 4, cooldowns: 1,
                             minMain: 3, maxMain: 4, setsOverride: 2, volume: 0.6, maxMinutes: 20)
        case .recovery:
            return FocusPlan(main: [(.mobility, 1)], finisher: [], warmups: 1, cooldowns: 0, minMain: 5, maxMain: 9, maxMinutes: 30)
        case .mobility:
            return FocusPlan(main: [(.mobility, 0.85), (.balance, 0.15)], finisher: [], warmups: 2, cooldowns: 0, minMain: 6, maxMain: 12)
        case .power:
            return FocusPlan(main: [(.power, 0.55), (.lowerBody, 0.25), (.core, 0.2)], finisher: [.speed, .conditioning], warmups: 4, cooldowns: 2, minMain: 4, maxMain: 8)
        case .strength:
            return FocusPlan(main: [(.lowerBody, 0.45), (.upperBody, 0.35), (.core, 0.2)], finisher: [.core], warmups: 4, cooldowns: 2, minMain: 4, maxMain: 8)
        case .speed:
            return FocusPlan(main: [(.speed, 0.55), (.power, 0.25), (.balance, 0.2)], finisher: [.conditioning], warmups: 4, cooldowns: 2, minMain: 4, maxMain: 8)
        case .conditioning:
            return FocusPlan(main: [(.conditioning, 0.55), (.power, 0.2), (.core, 0.25)], finisher: [.core], warmups: 3, cooldowns: 2, minMain: 4, maxMain: 8)
        case .core:
            return FocusPlan(main: [(.core, 0.7), (.balance, 0.3)], finisher: [.conditioning], warmups: 3, cooldowns: 2, minMain: 4, maxMain: 9)
        case .hands:
            return FocusPlan(main: [(.stickhandling, 0.55), (.shooting, 0.3), (.core, 0.15)], finisher: [.speed], warmups: 3, cooldowns: 1, minMain: 4, maxMain: 9)
        case .fullBody:
            return FocusPlan(main: [(.lowerBody, 0.25), (.upperBody, 0.2), (.power, 0.2), (.core, 0.2), (.conditioning, 0.15)], finisher: [.conditioning], warmups: 4, cooldowns: 2, minMain: 5, maxMain: 9)
        case .goalie:
            return FocusPlan(main: [(.goalie, 0.5), (.balance, 0.2), (.mobility, 0.15), (.speed, 0.15)], finisher: [.core], warmups: 4, cooldowns: 2, minMain: 4, maxMain: 8)
        case .custom:
            return FocusPlan(main: [(.lowerBody, 0.5), (.core, 0.5)], finisher: [], warmups: 3, cooldowns: 2, minMain: 4, maxMain: 8)
        }
    }

    private static func tune(_ plan: inout FocusPlan, for position: Position, focus: Focus) {
        guard focus != .recovery && focus != .mobility && focus != .activation else { return }
        let boost: Set<Category>
        switch position {
        case .forward: boost = [.speed, .power]
        case .defense: boost = [.lowerBody, .upperBody]
        case .goalie:
            if !plan.main.contains(where: { $0.0 == .goalie }) { plan.main.append((.goalie, 0.2)) }
            return
        }
        for i in plan.main.indices where boost.contains(plan.main[i].0) {
            plan.main[i].1 *= 1.2
        }
    }

    /// A same-category replacement for an item, respecting equipment.
    static func swap(_ item: WorkoutItem, in workout: Workout, settings: Settings) -> WorkoutItem? {
        guard let old = item.exercise else { return nil }
        let inUse = Set(workout.items.map(\.exerciseID))
        let candidates = Library.all.filter {
            $0.category == old.category && !inUse.contains($0.id)
                && $0.equipment.allSatisfy { settings.equipment.contains($0) }
                && (old.category != .mobility || item.block != .cooldown || $0.tags.contains(.cooldown))
        }
        guard let ex = candidates.randomElement() else { return nil }
        let ratio = Double(item.base) / Double(max(1, old.base))
        var new = item
        new.id = UUID()
        new.exerciseID = ex.id
        new.base = ex.measure.round(Double(ex.base) * ratio)
        if old.measure != ex.measure { new.base = ex.base }
        return new
    }
}
