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
    var restScale: Double = 1
}

enum Generator {
    /// Rough duration estimate for one item, in seconds.
    static func seconds(sets: Int, value: Int, measure: Measure, perSide: Bool, rest: Int, hill: Bool = false) -> Int {
        let sides = perSide ? 2 : 1
        // A hill trip (up and back down) takes about a minute and a half.
        if hill { return sets * value * 90 * sides + 10 }
        let work: Int
        switch measure {
        case .reps: work = value * 3 * sides
        case .seconds: work = value * sides + (perSide ? 5 : 0)
        case .meters: work = (value / 4 + 4) * sides
        case .lines: work = value * 15
        }
        return sets * (work + 8) + max(0, sets - 1) * rest + 10
    }

    static func make(focus: Focus, minutes: Int, seed: UInt64, settings: Settings, afterEvent: DayType? = nil) -> Workout {
        var rng = SeededRNG(seed: seed &+ UInt64(Focus.allCases.firstIndex(of: focus) ?? 0) &* 104_729)
        var plan = plan(for: focus, sport: settings.sport)
        // Training after a game or practice: less volume, no explosive or heavy-leg work, more stretching.
        var settings = settings
        if afterEvent == .game {
            settings.lowImpact = true
            plan.volume *= 0.85
            plan.setsOverride = min(plan.setsOverride ?? 3, 3)
            settings.cooldownCount += 1
            plan.main = plan.main.filter { $0.0 != .lowerBody || plan.main.count == 1 }
        } else if afterEvent == .practice {
            plan.volume *= 0.92
            settings.cooldownCount += 1
        }
        tune(&plan, for: settings.position, focus: focus, settings: settings)
        let minutes = min(minutes, plan.maxMinutes ?? minutes)

        let hockeyFocus = focus == .hands || focus == .goalie
        let hockeyOnly: Set<Category> = [.stickhandling, .shooting, .goalie]
        let available = Library.all.filter { ex -> Bool in
            if settings.excluded.contains(ex.id) || ex.level > settings.maxLevel || ex.id == "cooldown-jog" { return false }
            if !ex.equipment.allSatisfy({ settings.equipment.contains($0) }) { return false }
            if ex.category == .goalie && settings.position != .goalie && focus != .goalie { return false }
            if !settings.includeHockey && !hockeyFocus && hockeyOnly.contains(ex.category) { return false }
            if settings.sport == .track && hockeyOnly.contains(ex.category) && !hockeyFocus { return false }
            if settings.sport == .hockey && Category.trackOnly.contains(ex.category) && !Focus.track.contains(focus) { return false }
            if settings.lowImpact && (ex.tags.contains(.explosive) || ex.category == .power) { return false }
            return true
        }
        func pool(_ cat: Category) -> [Exercise] { available.filter { $0.category == cat } }

        var used = Set<String>()
        var items: [WorkoutItem] = []

        func makeItem(_ ex: Exercise, _ block: Block) -> WorkoutItem {
            let isWork = block == .main || block == .finisher
            var sets = ex.sets
            var volume = 1.0
            if isWork {
                sets = max(1, ex.sets + settings.phase.setsDelta + (ex.sets > 1 ? settings.extraSets : 0))
                volume = settings.phase.volume * plan.volume
                if let o = plan.setsOverride { sets = min(sets, o) }
            }
            let base = ex.measure.round(Double(ex.base) * volume)
            let rest = isWork ? Int((Double(ex.category.defaultRest) * settings.rest.multiplier * plan.restScale).rounded()) : 5
            return WorkoutItem(exerciseID: ex.id, sets: sets, base: base, rest: rest, block: block)
        }
        func cost(_ item: WorkoutItem) -> Int {
            guard let ex = item.exercise else { return 0 }
            return seconds(sets: item.sets, value: item.base, measure: ex.measure, perSide: ex.perSide, rest: item.rest, hill: Library.isHill(ex))
        }
        func take(_ n: Int, from candidates: [Exercise], block: Block) -> [WorkoutItem] {
            guard n > 0 else { return [] }
            var c = candidates.filter { !used.contains($0.id) }
            c.shuffle(using: &rng)
            let picked = Array(c.prefix(n))
            picked.forEach { used.insert($0.id) }
            return picked.map { makeItem($0, block) }
        }

        let light = focus == .recovery || focus == .mobility
        let wantsJog = (settings.runMode == .warmupJog || settings.runMode == .both) && focus != .run && !light
        let wantsRunFinisher = (settings.runMode == .finisher || settings.runMode == .both)
            && ![.run, .activation, .recovery, .mobility].contains(focus)

        // Warm-up: walking/dynamic moves, then still stretches.
        var warm: [WorkoutItem] = []
        if wantsJog, let jog = Library.byID["warmup-jog"], !settings.excluded.contains(jog.id) {
            used.insert(jog.id)
            warm.append(makeItem(jog, .warmup))
        }
        switch settings.warmupMode {
        case .routine where !settings.warmupRoutine.isEmpty:
            for var it in settings.warmupRoutine where it.exercise != nil {
                it.id = UUID()
                used.insert(it.exerciseID)
                warm.append(it)
            }
        case .none:
            break
        default:
            let count = light ? min(plan.warmups, settings.warmupCount) : (focus == .activation ? plan.warmups : settings.warmupCount)
            let walking = pool(.warmup).filter { $0.tags.contains(.walking) && $0.id != "warmup-jog" }
            let still = pool(.warmup).filter { !$0.tags.contains(.walking) }
            let nWalk = (count + 1) / 2
            warm += take(nWalk, from: walking, block: .warmup)
            warm += take(count - nWalk, from: still, block: .warmup)
            if !light && focus != .activation {
                let statics = available.filter { Library.staticStretchIDs.contains($0.id) }
                warm += take(settings.stretchCount, from: statics, block: .stretch)
            }
        }
        items += warm

        // Cool-down (picked now so the budget is known)
        let coolPool = available.filter { $0.category == .mobility && $0.tags.contains(.cooldown) }
        let cool = take(light ? 0 : (focus == .activation ? plan.cooldowns : settings.cooldownCount), from: coolPool, block: .cooldown)

        var budget = minutes * 60 - warm.map(cost).reduce(0, +) - cool.map(cost).reduce(0, +)
        if !plan.finisher.isEmpty || wantsRunFinisher { budget -= 200 }
        budget -= settings.mustDos.map(cost).reduce(0, +)

        // Main. Priority exercises (set from the library) come up more often; top priority ones are added first.
        func priority(_ ex: Exercise) -> Int { settings.priorities[ex.id] ?? 0 }
        func weightedPick(_ list: [Exercise]) -> Exercise? {
            let total = list.reduce(0.0) { $0 + pow(2.2, Double(priority($1))) }
            guard total > 0 else { return nil }
            var roll = Double.random(in: 0..<total, using: &rng)
            for ex in list {
                let w = pow(2.2, Double(priority(ex)))
                if roll < w { return ex }
                roll -= w
            }
            return list.last
        }
        var weights = plan.main.map { cw -> (Category, Double) in
            let boost = pool(cw.0).reduce(0.0) { $0 + Double(priority($1)) * 0.12 }
            return (cw.0, cw.1 * min(2, 1 + boost))
        }
        var main: [WorkoutItem] = []
        let planCats = Set(plan.main.map(\.0))
        for ex in available.filter({ priority($0) >= 3 && planCats.contains($0.category) && !used.contains($0.id) })
            .shuffled(using: &rng).prefix(2) {
            let item = makeItem(ex, .main)
            budget -= cost(item)
            used.insert(ex.id)
            main.append(item)
        }
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
            guard let ex = weightedPick(candidates) else {
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

        // Must-dos the player set as mandatory for every workout.
        for var it in settings.mustDos where it.exercise.map({ ex in
            settings.sport == .hockey ? !Category.trackOnly.contains(ex.category) : !Category.hockeyOnly.contains(ex.category)
        }) ?? false {
            it.id = UUID()
            it.block = .musts
            used.insert(it.exerciseID)
            items.append(it)
        }

        // Finisher
        if wantsRunFinisher {
            let short: Set<String> = ["strides", "sprints-200", "hill-sprints", "shuttle-run", "repeats-400"]
            items += take(1, from: pool(.running).filter { short.contains($0.id) }, block: .finisher)
        } else if let fCat = plan.finisher.randomElement(using: &rng) {
            items += take(1, from: pool(fCat), block: .finisher)
        }
        items += cool

        return Workout(title: focus.title, subtitle: focus.tagline, focus: focus, items: items)
    }

    private static func plan(for focus: Focus, sport: Sport) -> FocusPlan {
        switch focus {
        case .activation where sport == .track:
            return FocusPlan(main: [(.sprints, 0.6), (.power, 0.2), (.balance, 0.2)], finisher: [], warmups: 5, cooldowns: 1,
                             minMain: 3, maxMain: 4, setsOverride: 2, volume: 0.6, maxMinutes: 25)
        case .trackSpeed:
            return FocusPlan(main: [(.sprints, 0.7), (.power, 0.3)], finisher: [.core], warmups: 6, cooldowns: 2, minMain: 3, maxMain: 6)
        case .speedEndurance:
            return FocusPlan(main: [(.sprints, 0.7), (.running, 0.3)], finisher: [.core], warmups: 6, cooldowns: 2, minMain: 2, maxMain: 4)
        case .tempo:
            return FocusPlan(main: [(.running, 0.6), (.core, 0.4)], finisher: [], warmups: 4, cooldowns: 3, minMain: 2, maxMain: 5)
        case .hurdleDay:
            return FocusPlan(main: [(.hurdles, 0.7), (.sprints, 0.3)], finisher: [.core], warmups: 5, cooldowns: 2, minMain: 4, maxMain: 7)
        case .jumpDay:
            return FocusPlan(main: [(.jumps, 0.7), (.power, 0.3)], finisher: [.core], warmups: 5, cooldowns: 2, minMain: 4, maxMain: 7)
        case .throwDay:
            return FocusPlan(main: [(.throwing, 0.7), (.power, 0.15), (.upperBody, 0.15)], finisher: [.core], warmups: 4, cooldowns: 2, minMain: 4, maxMain: 7)
        case .distance:
            return FocusPlan(main: [(.running, 1)], finisher: [.core], warmups: 3, cooldowns: 3, minMain: 1, maxMain: 3)
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
        case .upper:
            return FocusPlan(main: [(.upperBody, 0.8), (.core, 0.2)], finisher: [.conditioning, .core], warmups: 3, cooldowns: 2, minMain: 4, maxMain: 9)
        case .legs:
            return FocusPlan(main: [(.lowerBody, 0.75), (.power, 0.15), (.balance, 0.1)], finisher: [.conditioning], warmups: 4, cooldowns: 2, minMain: 4, maxMain: 9)
        case .abs:
            return FocusPlan(main: [(.core, 1)], finisher: [.conditioning], warmups: 3, cooldowns: 2, minMain: 5, maxMain: 10)
        case .hiit:
            return FocusPlan(main: [(.conditioning, 0.6), (.power, 0.2), (.core, 0.2)], finisher: [.core], warmups: 3, cooldowns: 2, minMain: 5, maxMain: 10, restScale: 0.6)
        case .run:
            return FocusPlan(main: [(.running, 1)], finisher: [.core], warmups: 4, cooldowns: 2, minMain: 1, maxMain: 3)
        case .custom:
            return FocusPlan(main: [(.lowerBody, 0.5), (.core, 0.5)], finisher: [], warmups: 3, cooldowns: 2, minMain: 4, maxMain: 8)
        }
    }

    private static func tune(_ plan: inout FocusPlan, for position: Position, focus: Focus, settings: Settings) {
        guard [.power, .strength, .speed, .conditioning, .fullBody, .core].contains(focus), settings.style != .general else { return }
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
        let candidates = Library.all.filter { ex -> Bool in
            if inUse.contains(ex.id) || settings.excluded.contains(ex.id) { return false }
            if !ex.equipment.allSatisfy({ settings.equipment.contains($0) }) { return false }
            switch item.block {
            case .stretch: return Library.staticStretchIDs.contains(ex.id)
            case .cooldown: return ex.category == old.category && (old.category != .mobility || ex.tags.contains(.cooldown))
            case .warmup: return ex.category == old.category && old.tags.contains(.walking) == ex.tags.contains(.walking)
            default: return ex.category == old.category
            }
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
