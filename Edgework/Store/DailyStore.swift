import Foundation

extension Store {
    // MARK: Daily log

    func daily(_ date: Date = Date()) -> DailyLog { data.daily[Day.key(date)] ?? DailyLog() }

    func updateDaily(_ date: Date = Date(), _ change: (inout DailyLog) -> Void) {
        var d = daily(date)
        change(&d)
        data.daily[Day.key(date)] = d
    }

    func addShots(_ type: ShotType, _ n: Int, date: Date = Date()) {
        updateDaily(date) { $0.shots[type.rawValue] = max(0, ($0.shots[type.rawValue] ?? 0) + n) }
        haptic(.light)
    }

    var weekRunKm: Double {
        Day.week(of: Date()).reduce(0) { $0 + daily($1).runKm }
    }

    /// Credits shots, stickhandling minutes and running distance from a finished workout.
    func creditDaily(from record: SessionRecord) {
        updateDaily(record.date) { d in
            for e in record.entries {
                guard let ex = Library.byID[e.exerciseID] else { continue }
                let sides = ex.perSide ? 2 : 1
                if let t = ShotType.exerciseMap[e.exerciseID], e.measure == .reps {
                    d.shots[t.rawValue, default: 0] += e.sets * e.value
                } else if ex.category == .stickhandling {
                    d.stickMinutes += e.measure == .seconds ? max(1, e.sets * e.value * sides / 60) : e.sets
                } else if ex.category == .running || ex.id == "warmup-jog" {
                    switch e.measure {
                    case .meters: d.runKm += Double(e.sets * e.value) / 1000
                    case .seconds: d.runKm += Double(e.sets * e.value) / 360
                    case .reps, .lines: d.runKm += Double(e.sets * e.value) * 0.03
                    }
                }
            }
        }
    }

    /// 1.0 normally; lower on days you chose to lighten after a rough check-in.
    var todayScale: Double { data.dayScale[Day.key(Date())] ?? 1 }

    // MARK: Food

    func foods(on date: Date) -> [FoodEntry] {
        let k = Day.key(date)
        return data.foods.filter { Day.key($0.date) == k }
    }

    func totals(on date: Date) -> (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        var t = (kcal: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0)
        for e in foods(on: date) {
            t.kcal += e.kcal
            t.protein += e.protein
            t.carbs += e.carbs
            t.fat += e.fat
        }
        return t
    }

    func addFood(_ food: Food, servings: Double, meal: Meal, date: Date) {
        let stamp = Day.key(date) == Day.key(Date()) ? Date() : Day.start(date).addingTimeInterval(12 * 3600)
        data.foods.append(FoodEntry(food: food, servings: servings, meal: meal, date: stamp))
        // Water-like drinks fill the water goal, 8 oz to a glass.
        if food.hydrates { updateDaily(date) { $0.water += max(1, Int((servings * (food.servingOz ?? 8) / 8).rounded())) } }
        haptic(.light)
    }

    func removeFood(_ id: UUID) { data.foods.removeAll { $0.id == id } }

    /// Keeps scanned and custom foods in "My foods" so they're searchable later.
    func saveToLibrary(_ food: Food) {
        if let i = data.customFoods.firstIndex(where: { $0.id == food.id }) {
            data.customFoods[i] = food
        } else {
            data.customFoods.insert(food, at: 0)
        }
    }

    var recentFoods: [Food] {
        var seen = Set<String>()
        var out: [Food] = []
        for e in data.foods.sorted(by: { $0.date > $1.date }) where !seen.contains(e.food.id) {
            seen.insert(e.food.id)
            out.append(e.food)
            if out.count >= 15 { break }
        }
        return out
    }

    func searchFoods(_ q: String) -> [Food] {
        let pool = data.customFoods + FoodDB.all
        guard !q.isEmpty else { return pool }
        return pool.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.group.title.localizedCaseInsensitiveContains(q)
            || $0.benefits.contains { $0.title.localizedCaseInsensitiveContains(q) } }
    }

    var targets: NutritionTargets {
        let s = data.settings
        let bmr = 10 * s.weightKg + 6.25 * s.heightCm - 5 * Double(s.age) + (s.sex == .male ? 5 : -161)
        var kcal = bmr * 1.65 + s.nutritionGoal.kcalDelta
        if s.kcalOverride > 0 { kcal = Double(s.kcalOverride) }
        let protein = s.proteinOverride > 0 ? Double(s.proteinOverride) : s.weightKg * (s.nutritionGoal == .lose ? 2.0 : 1.8)
        let fat = kcal * 0.28 / 9
        let carbs = max(0, (kcal - protein * 4 - fat * 9) / 4)
        return NutritionTargets(kcal: kcal.rounded(), protein: protein.rounded(), carbs: carbs.rounded(), fat: fat.rounded(), water: s.waterGoal)
    }

    // MARK: Units

    func weightText(_ kg: Double) -> String {
        data.settings.units == .imperial ? String(format: "%.1f lb", kg * 2.20462) : String(format: "%.1f kg", kg)
    }

    func distanceText(_ km: Double) -> String {
        data.settings.units == .imperial ? String(format: "%.1f mi", km * 0.621371) : String(format: "%.1f km", km)
    }

    // MARK: Must-dos

    func programWorkout(_ program: Program) -> Workout {
        var w = program.workout(rest: data.settings.rest)
        if data.settings.mustDosInPrograms {
            for var it in data.settings.mustDos where it.exercise.map({ ex in
                data.settings.sport == .hockey ? !Category.trackOnly.contains(ex.category) : !Category.hockeyOnly.contains(ex.category)
            }) ?? false {
                it.id = UUID()
                it.block = .musts
                w.items.append(it)
            }
        }
        return w
    }

    // MARK: Required + priority (set from the library)

    func isRequired(_ id: String) -> Bool { data.settings.mustDos.contains { $0.exerciseID == id } }

    func setRequired(_ ex: Exercise, _ on: Bool) {
        if on {
            guard !isRequired(ex.id) else { return }
            var item = self.item(for: ex, block: .main)
            item.block = .musts
            data.settings.mustDos.append(item)
        } else {
            data.settings.mustDos.removeAll { $0.exerciseID == ex.id }
        }
        rebuildTodayIfAuto()
    }

    func priority(_ id: String) -> Int { data.settings.priorities[id] ?? 0 }

    func setPriority(_ id: String, _ p: Int) {
        data.settings.priorities[id] = p <= 0 ? nil : min(3, p)
        if p > 0 { data.settings.excluded.remove(id) }
        rebuildTodayIfAuto()
    }

    func rebuildTodayIfAuto() {
        guard let t = data.today else { return }
        rebuildToday(seed: t.seed, focus: t.focus, duration: t.duration)
    }

    static let priorityNames = ["Normal", "Often", "A lot", "Every time it fits"]

    static let mustDoPresets: [(title: String, items: [(String, Int, Int)])] = [
        ("100 shots", [("wrist-shots", 2, 25), ("snap-shots", 1, 25), ("backhands", 1, 25)]),
        ("Mandatory 2 km run", [("distance-run", 1, 2000)]),
        ("20-minute run", [("easy-run", 1, 1200)]),
        ("10 min stickhandling", [("stickhandling-session", 1, 600)]),
        ("50 slap shots", [("slap-shots", 5, 10)]),
        ("Core finisher", [("plank", 2, 60), ("side-plank", 1, 30)]),
        ("Push-up & sit-up challenge", [("push-up", 3, 20), ("sit-up", 3, 20)]),
    ]

    func addMustDoPreset(_ index: Int) {
        guard Store.mustDoPresets.indices.contains(index) else { return }
        for (id, sets, base) in Store.mustDoPresets[index].items {
            guard let ex = Library.byID[id] else { continue }
            var item = self.item(for: ex, block: .main)
            item.block = .musts
            item.sets = sets
            item.base = base
            data.settings.mustDos.append(item)
        }
    }
}
