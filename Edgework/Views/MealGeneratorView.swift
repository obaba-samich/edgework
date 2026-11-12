import SwiftUI

/// Builds a meal from foods you have on hand, sized to what's left of today's targets.
enum MealBuilder {
    struct Pick: Identifiable, Hashable {
        var food: Food
        var servings: Double
        var id: String { food.id }
    }

    /// Share of the day's calories each meal should cover.
    static func share(_ meal: Meal) -> Double {
        switch meal {
        case .breakfast: 0.25
        case .lunch: 0.3
        case .dinner: 0.32
        case .snack: 0.1
        case .preGame: 0.15
        case .postWorkout: 0.15
        case .drinks: 0.05
        }
    }

    static func build(meal: Meal, pool: [Food], kcalTarget: Double, proteinTarget: Double, seed: Int) -> [Pick] {
        var rng = SeededRNG(seed: UInt64(max(0, seed)))
        let usable = pool.filter { $0.kcal > 0 && $0.group != .sweet }
        func pick(_ filter: (Food) -> Bool) -> Food? {
            usable.filter(filter).shuffled(using: &rng).first
        }
        let proteinRich: (Food) -> Bool = { $0.protein * 4 >= $0.kcal * 0.35 }
        let carbRich: (Food) -> Bool = { $0.carbs * 4 >= $0.kcal * 0.55 && $0.group != .drink }
        let lowFatFiber: (Food) -> Bool = { $0.fat <= 8 && $0.fiber <= 5 }

        var foods: [Food] = []
        switch meal {
        case .preGame:
            // Carb-forward, easy to digest.
            if let c = pick({ carbRich($0) && lowFatFiber($0) && $0.benefits.contains(.energy) }) ?? pick({ carbRich($0) && lowFatFiber($0) }) { foods.append(c) }
            if let f = pick({ $0.group == .fruit && lowFatFiber($0) && !foods.contains($0) }) { foods.append(f) }
            if let p = pick({ proteinRich($0) && $0.fat <= 10 }) { foods.append(p) }
        case .postWorkout:
            if let p = pick({ proteinRich($0) && $0.benefits.contains(.recovery) }) ?? pick(proteinRich) { foods.append(p) }
            if let c = pick({ carbRich($0) && $0.benefits.contains(.energy) && $0.group != .snack && !foods.contains($0) })
                ?? pick({ carbRich($0) && !foods.contains($0) }) { foods.append(c) }
            if let f = pick({ $0.group == .fruit && !foods.contains($0) }) { foods.append(f) }
        case .snack, .drinks:
            if let a = pick({ meal == .drinks ? $0.group == .drink : ($0.group == .snack || $0.group == .fruit || $0.group == .dairy || $0.group == .fats) }) { foods.append(a) }
            if meal == .snack, let b = pick({ proteinRich($0) && !foods.contains($0) && $0.kcal < 250 }) { foods.append(b) }
        default:
            if let p = pick({ proteinRich($0) && $0.group != .drink }) { foods.append(p) }
            if let c = pick({ carbRich($0) && !foods.contains($0) }) { foods.append(c) }
            if let v = pick({ ($0.group == .vegetable || $0.group == .fruit) && !foods.contains($0) }) { foods.append(v) }
            if meal == .breakfast, let d = pick({ ($0.group == .dairy || $0.group == .drink) && !foods.contains($0) }) { foods.append(d) }
        }
        guard !foods.isEmpty else { return [] }

        // Scale servings in half steps so the meal lands near its calorie share.
        var picks = foods.map { Pick(food: $0, servings: 1) }
        func total() -> Double { picks.reduce(0) { $0 + $1.food.kcal * $1.servings } }
        for _ in 0..<12 {
            let t = total()
            if t < kcalTarget * 0.85, let i = picks.indices.min(by: { picks[$0].servings < picks[$1].servings }) {
                picks[i].servings = min(4, picks[i].servings + 0.5)
            } else if t > kcalTarget * 1.15, let i = picks.indices.max(by: { picks[$0].food.kcal * picks[$0].servings < picks[$1].food.kcal * picks[$1].servings }),
                      picks[i].servings > 0.5 {
                picks[i].servings -= 0.5
            } else {
                break
            }
        }
        return picks
    }
}

struct MealGeneratorView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var meal: Meal
    let date: Date
    @State private var seed = Int.random(in: 1...999_999)
    @State private var useAll = false
    @State private var editingPantry = false
    @State private var added = false

    private var pool: [Food] {
        let all = store.data.customFoods + FoodDB.all
        if useAll || store.data.pantry.isEmpty { return all }
        return all.filter { store.data.pantry.contains($0.id) }
    }

    private var targets: (kcal: Double, protein: Double) {
        let t = store.targets
        let eaten = store.totals(on: date)
        let left = max(t.kcal * 0.08, t.kcal - eaten.kcal)
        let share = MealBuilder.share(meal) * t.kcal
        return (min(max(share, 120), left), t.protein * MealBuilder.share(meal))
    }

    var body: some View {
        let picks = MealBuilder.build(meal: meal, pool: pool, kcalTarget: targets.kcal, proteinTarget: targets.protein, seed: seed)
        let kcal = picks.reduce(0) { $0 + $1.food.kcal * $1.servings }
        let protein = picks.reduce(0) { $0 + $1.food.protein * $1.servings }
        let carbs = picks.reduce(0) { $0 + $1.food.carbs * $1.servings }
        let fat = picks.reduce(0) { $0 + $1.food.fat * $1.servings }
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Meal.allCases) { m in
                                Button { meal = m } label: { Chip(text: m.title, symbol: m.symbol, color: m.color, filled: meal == m) }
                                    .buttonStyle(PressableStyle())
                            }
                        }
                    }
                    if store.data.pantry.isEmpty && !useAll {
                        HStack(spacing: 12) {
                            Image(systemName: "basket.fill").foregroundStyle(Theme.amber)
                            Text("Your pantry is empty, so ideas come from every food. Set up your pantry to only use what you have.")
                                .font(.footnote).foregroundStyle(Theme.text2)
                        }
                        .cardStyle(padding: 12)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Overline("Suggested \(meal.title.lowercased())", color: meal.color)
                        if picks.isEmpty {
                            Text("Not enough foods in your pantry for this meal. Add more, or use every food.")
                                .font(.subheadline).foregroundStyle(Theme.text2)
                        }
                        ForEach(picks) { p in
                            HStack(spacing: 12) {
                                IconBadge(symbol: p.food.group.symbol, color: meal.color, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.food.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                                    Text("\(p.servings == p.servings.rounded() ? "\(Int(p.servings))" : String(format: "%.1f", p.servings)) × \(p.food.serving)")
                                        .font(.caption).foregroundStyle(Theme.text2)
                                }
                                Spacer()
                                Text("\(Int(p.food.kcal * p.servings))").font(.number(15)).foregroundStyle(Theme.text)
                            }
                        }
                        if !picks.isEmpty {
                            Divider().overlay(Theme.stroke)
                            HStack {
                                Text("\(Int(kcal)) kcal").font(.number(16)).foregroundStyle(Theme.text)
                                Spacer()
                                Text("P \(Int(protein)) · C \(Int(carbs)) · F \(Int(fat))").font(.number(13)).foregroundStyle(Theme.text2)
                            }
                            Text("Aimed at about \(Int(targets.kcal)) kcal, based on what's left today.").font(.caption).foregroundStyle(Theme.text3)
                        }
                    }
                    .cardStyle()

                    HStack(spacing: 10) {
                        Button { seed += 1; store.haptic(.light) } label: { Label("Shuffle", systemImage: "dice") }
                            .buttonStyle(SecondaryButtonStyle())
                        Button {
                            for p in picks { store.addFood(p.food, servings: p.servings, meal: meal, date: date) }
                            store.notify(.success)
                            added = true
                        } label: { Label("Log it", systemImage: "checkmark") }
                            .buttonStyle(PrimaryButtonStyle(color: Theme.green))
                            .disabled(picks.isEmpty)
                    }

                    Toggle("Use every food, not just my pantry", isOn: $useAll)
                        .tint(Theme.ice)
                        .cardStyle(padding: 14)
                    Button { editingPantry = true } label: {
                        Label("Edit my pantry (\(store.data.pantry.count) foods)", systemImage: "basket")
                    }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.amber))
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Meal Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(isPresented: $editingPantry) { NavigationStack { PantryView() }.environmentObject(store) }
            .alert("Logged to \(meal.title)", isPresented: $added) { Button("OK", role: .cancel) { dismiss() } }
        }
    }
}

struct PantryView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private static let staples = ["eggs", "oatmeal", "banana", "apple", "milk", "greek-yogurt", "peanut-butter", "wheat-bread", "white-rice",
                                  "pasta", "chicken-breast", "ground-beef", "tuna", "cheddar", "broccoli", "carrots", "potato", "frozen-veg",
                                  "orange", "almonds", "string-cheese", "tortilla", "black-beans", "spinach"]

    var body: some View {
        let foods = (store.data.customFoods + FoodDB.all).filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        List {
            Section {
                Button("Add common staples") {
                    for id in Self.staples where FoodDB.byID[id] != nil { store.data.pantry.insert(id) }
                }
                if !store.data.pantry.isEmpty {
                    Button("Clear pantry", role: .destructive) { store.data.pantry = [] }
                }
            } footer: { Text("Check what's in your kitchen. The meal generator only uses these.") }
            .listRowBackground(Theme.surface)
            ForEach(FoodGroup.allCases) { g in
                let items = foods.filter { $0.group == g }
                if !items.isEmpty {
                    Section(g.title) {
                        ForEach(items) { f in
                            let on = store.data.pantry.contains(f.id)
                            Button {
                                if on { store.data.pantry.remove(f.id) } else { store.data.pantry.insert(f.id) }
                            } label: {
                                HStack {
                                    Text(f.name).foregroundStyle(Theme.text)
                                    Spacer()
                                    Image(systemName: on ? "checkmark.circle.fill" : "circle").foregroundStyle(on ? Theme.green : Theme.text3)
                                }
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .searchable(text: $query, prompt: "Search foods")
        .navigationTitle("My Pantry (\(store.data.pantry.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}
