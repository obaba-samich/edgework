import SwiftUI

// MARK: - Drinks

extension Food {
    /// Drinks are logged by volume and some count toward water.
    var isDrink: Bool {
        if group == .drink { return true }
        let n = name.lowercased()
        let liquid = ["milk", "juice", "shake", "smoothie", "water", "tea", "coffee", "lemonade", "kombucha"].contains { n.contains($0) }
        return liquid && servingOz != nil && !n.contains("powder")
    }

    /// Fluid ounces in one serving, read from text like "8 oz", "16.9 fl oz", "1 cup" or "250 ml".
    var servingOz: Double? {
        let s = serving.lowercased()
        func number(before unit: String) -> Double? {
            guard let r = s.range(of: #"(\d+(\.\d+)?)\s*"# + unit, options: .regularExpression) else { return nil }
            let digits = s[r].prefix { "0123456789.".contains($0) }
            return Double(digits)
        }
        if let ml = number(before: "ml") { return ml / 29.5735 }
        if let l = number(before: "l\\b") { return l * 33.814 }
        if let oz = number(before: "(fl\\s*)?oz") { return oz }
        if s.contains("cup") { return (number(before: "cups?") ?? 1) * 8 }
        if s.contains("can") { return 12 }
        if s.contains("bottle") { return 16.9 }
        return nil
    }

    /// Water, zero-calorie electrolytes, plain tea and similar.
    var hydrates: Bool { isDrink && kcal <= 15 * max(1, (servingOz ?? 8) / 8) && !name.lowercased().contains("energy") }

    /// Sugar you drink: soda, juice, sweet coffee drinks. Sports drinks get a pass during long sessions.
    var sugaryDrink: Bool { isDrink && carbs >= 15 && protein < 5 && id != "sports-drink" }
}

// MARK: - Servings field

/// −/+ in fixed steps, plus a number you can type.
struct AmountField: View {
    @Binding var value: Double
    var step: Double = 0.25
    var range: ClosedRange<Double> = 0.1...50
    var unit = ""
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundIconButton(symbol: "minus", size: 36) { set(stepped(-1)) }
            HStack(spacing: 3) {
                TextField("1", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.number(20))
                    .focused($focused)
                    .frame(width: 64)
                    .onChange(of: text) { _, t in
                        if let v = Double(t.replacingOccurrences(of: ",", with: ".")), v > 0 { value = min(range.upperBound, v) }
                    }
                if !unit.isEmpty { Text(unit).font(.caption.weight(.semibold)).foregroundStyle(Theme.text2) }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface2))
            RoundIconButton(symbol: "plus", size: 36) { set(stepped(1)) }
        }
        .onAppear { text = Self.format(value) }
        .onChange(of: value) { _, v in if !focused { text = Self.format(v) } }
        .toolbar {
            if focused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false; text = Self.format(value) }
                }
            }
        }
    }

    private func stepped(_ dir: Double) -> Double {
        let q = value / step
        // A typed value between steps moves to the next step in that direction, so 1.3 then + is 1.5.
        if abs(q.rounded() - q) > 0.001 { return (dir > 0 ? q.rounded(.up) : q.rounded(.down)) * step }
        return value + dir * step
    }

    private func set(_ v: Double) {
        focused = false
        value = min(range.upperBound, max(range.lowerBound, (v * 1000).rounded() / 1000))
        text = Self.format(value)
    }

    static func format(_ v: Double) -> String {
        if v == v.rounded() { return "\(Int(v))" }
        var s = String(format: "%.2f", v)
        while s.hasSuffix("0") { s.removeLast() }
        return s
    }
}

// MARK: - Food editor

/// Tweak any food (the generic donut becomes "Lau's maple long john") and save it as your own.
struct FoodEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let food: Food
    /// True when editing something already in My Foods: saves in place.
    var editingSaved = false
    let onSave: (Food) -> Void

    @State private var name = ""
    @State private var serving = ""
    @State private var group = FoodGroup.snack
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var note = ""
    @State private var scale = 1.0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Serving size", text: $serving)
                    Picker("Group", selection: $group) {
                        ForEach(FoodGroup.allCases) { Text($0.title).tag($0) }
                    }
                } footer: {
                    if !editingSaved { Text("Based on \(food.name). Saving makes a new food in My Foods; the original stays.") }
                }
                .listRowBackground(Theme.surface)
                Section {
                    field("Calories", $kcal)
                    field("Protein (g)", $protein)
                    field("Carbs (g)", $carbs)
                    field("Fat (g)", $fat)
                    field("Fiber (g)", $fiber)
                } header: { Text("Per serving") }
                .listRowBackground(Theme.surface)
                Section {
                    HStack {
                        Text("Scale everything")
                        Spacer()
                        ForEach([0.5, 0.75, 1.25, 1.5], id: \.self) { f in
                            Button("×\(AmountField.format(f))") { scaleAll(f) }
                                .buttonStyle(.borderless)
                                .font(.footnote.weight(.semibold))
                        }
                    }
                } footer: { Text("Bigger or smaller than the generic one? Scale all the numbers at once.") }
                .listRowBackground(Theme.surface)
                Section("Note") {
                    TextField("Where it's from, what's in it", text: $note, axis: .vertical)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .screenBackground()
            .navigationTitle(editingSaved ? "Edit food" : "Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingSaved ? "Save" : "Save as new") { save() }
                        .fontWeight(.bold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
        }
    }

    private func load() {
        name = food.name
        serving = food.serving
        group = food.group
        kcal = AmountField.format(food.kcal)
        protein = AmountField.format(food.protein)
        carbs = AmountField.format(food.carbs)
        fat = AmountField.format(food.fat)
        fiber = AmountField.format(food.fiber)
        note = food.note
    }

    private func n(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private func scaleAll(_ f: Double) {
        func sc(_ s: String) -> String { AmountField.format((n(s) * f * 10).rounded() / 10) }
        kcal = AmountField.format((n(kcal) * f).rounded())
        protein = sc(protein); carbs = sc(carbs); fat = sc(fat); fiber = sc(fiber)
    }

    private func save() {
        var out = food
        if !editingSaved { out.id = "custom-\(UUID().uuidString)" }
        out.name = name.trimmingCharacters(in: .whitespaces)
        out.serving = serving.isEmpty ? "1 serving" : serving
        out.group = group
        out.kcal = n(kcal); out.protein = n(protein); out.carbs = n(carbs); out.fat = n(fat); out.fiber = n(fiber)
        out.note = note
        out.source = editingSaved ? food.source : "My foods (from \(food.name))"
        store.saveToLibrary(out)
        store.notify(.success)
        dismiss()
        onSave(out)
    }
}

// MARK: - Diet notes

/// Looks at the last week of logging and says what to eat more of, what to cut back on, and foods to try.
struct DietReport {
    struct Note: Identifiable {
        var id: String { title }
        let title: String
        let detail: String
        let symbol: String
        let color: Color
        var foods: [String] = []
    }

    var days = 0
    var more: [Note] = []
    var less: [Note] = []
    var good: [Note] = []

    @MainActor
    static func build(_ store: Store) -> DietReport {
        var r = DietReport()
        let t = store.targets
        let st = store.data.settings
        // Whole days only: today is still in progress, so it would always look like under-eating.
        let start = Day.add(-7, to: Day.start(Date()))
        let todayStart = Day.start(Date())
        let entries = store.data.foods.filter { $0.date >= start && $0.date < todayStart }
        let dayKeys = Set(entries.map { Day.key($0.date) })
        r.days = dayKeys.count
        guard r.days > 0 else { return r }
        let d = Double(r.days)
        func avg(_ f: (FoodEntry) -> Double) -> Double { entries.reduce(0) { $0 + f($1) } / d }

        let kcal = avg(\.kcal)
        let protein = avg(\.protein)
        let carbs = avg(\.carbs)
        let fiber = avg { $0.food.fiber * $0.servings }
        let produce = avg { ($0.food.group == .fruit || $0.food.group == .vegetable) ? $0.servings : 0 }
        let veg = avg { $0.food.group == .vegetable ? $0.servings : 0 }
        let sweets = avg { $0.food.group == .sweet ? $0.kcal : 0 }
        let drinkSugar = avg { $0.food.sugaryDrink ? $0.kcal : 0 }
        let snacks = avg { $0.food.group == .snack && $0.food.protein < 5 ? $0.kcal : 0 }
        let fatPct = kcal > 0 ? avg { $0.fat } * 9 / kcal : 0
        let water = store.data.daily.filter { dayKeys.contains($0.key) }.map(\.value.water).reduce(0, +)
        let waterAvg = Double(water) / d
        let iron = avg { $0.food.benefits.contains(.iron) ? $0.servings : 0 }
        let calcium = avg { $0.food.group == .dairy || $0.food.benefits.contains(.bones) ? $0.servings : 0 }
        let breakfasts = Set(entries.filter { $0.meal == .breakfast }.map { Day.key($0.date) }).count
        let postWorkout = entries.contains { $0.meal == .postWorkout }

        // Eat more
        if protein < t.protein * 0.85 {
            r.more.append(Note(title: "More protein", detail: "About \(Int(protein)) g a day vs your \(Int(t.protein)) g target. Add 20–30 g at a meal or two.",
                               symbol: "fish.fill", color: Theme.green, foods: ["greek-yogurt", "chicken-breast", "eggs", "tuna", "choc-milk", "cottage-cheese"]))
        }
        if kcal < t.kcal * 0.8 {
            r.more.append(Note(title: "Eat more overall", detail: "You're about \(Int(t.kcal - kcal)) kcal a day under. Under-eating slows recovery and you'll feel flat.",
                               symbol: "flame.fill", color: Theme.amber, foods: ["peanut-butter", "oatmeal", "white-rice", "pasta", "trail-mix", "bagel"]))
        } else if carbs < t.carbs * 0.75 {
            r.more.append(Note(title: "More carbs on training days", detail: "Carbs are the fuel for hard skating and sprinting: \(Int(carbs)) g vs about \(Int(t.carbs)) g.",
                               symbol: "bolt.fill", color: Theme.amber, foods: ["white-rice", "pasta", "banana", "oatmeal", "potato", "bagel"]))
        }
        if produce < 4 {
            r.more.append(Note(title: veg < 1.5 ? "More vegetables" : "More fruit and veg", detail: "About \(AmountField.format((produce * 10).rounded() / 10)) servings a day. Aim for 5+.",
                               symbol: "carrot.fill", color: Color(hex: 0x3DDC97), foods: ["broccoli", "spinach", "carrots", "blueberries", "apple", "orange"]))
        }
        if fiber < 22 {
            r.more.append(Note(title: "More fiber", detail: "About \(Int(fiber)) g a day. 25–35 g keeps energy steady (go light right before games).",
                               symbol: "leaf.fill", color: Color(hex: 0x4FD1C5), foods: ["oatmeal", "black-beans", "raspberries", "pear", "wheat-bread"]))
        }
        if waterAvg < Double(st.waterGoal) * 0.75 {
            r.more.append(Note(title: "More water", detail: "About \(AmountField.format((waterAvg * 10).rounded() / 10)) glasses a day vs \(st.waterGoal). Keep a bottle with you.",
                               symbol: "drop.fill", color: Theme.ice, foods: ["water", "electrolyte-zero", "watermelon", "orange"]))
        }
        if iron < 0.5 {
            r.more.append(Note(title: "Iron foods", detail: "Low iron shows up as early fatigue. Red meat, beans and greens a few times a week.",
                               symbol: "drop.triangle.fill", color: Color(hex: 0xC2410C), foods: ["ground-beef", "spinach", "black-beans", "lentils"]))
        }
        if calcium < 1 {
            r.more.append(Note(title: "Calcium", detail: "Bones take a beating in contact sports and sprinting. Dairy or fortified options daily.",
                               symbol: "figure.stand", color: Theme.text, foods: ["milk", "greek-yogurt", "cheddar", "string-cheese"]))
        }
        if r.days >= 3 && breakfasts < r.days / 2 {
            r.more.append(Note(title: "Eat breakfast", detail: "Breakfast showed up on \(breakfasts) of \(r.days) days. Something with protein and carbs sets the day up.",
                               symbol: "sunrise.fill", color: Theme.amber, foods: ["eggs", "oatmeal", "greek-yogurt", "banana"]))
        }
        if !postWorkout && !store.data.sessions.filter({ $0.date >= start }).isEmpty {
            r.more.append(Note(title: "Post-workout fuel", detail: "Nothing logged after training. Protein plus carbs within an hour helps you recover.",
                               symbol: "arrow.counterclockwise.heart.fill", color: Theme.green, foods: ["choc-milk", "greek-yogurt", "banana", "pbj"]))
        }

        // Cut back
        if drinkSugar > 100 {
            r.less.append(Note(title: "Sugary drinks", detail: "About \(Int(drinkSugar)) kcal a day from soda, juice and sweet drinks. Swap for water or zero-sugar electrolytes.",
                               symbol: "cup.and.saucer.fill", color: Theme.red))
        }
        if sweets > max(150, t.kcal * 0.1) {
            r.less.append(Note(title: "Treats", detail: "About \(Int(sweets)) kcal a day from sweets. Keep treats to around 10% of your day.",
                               symbol: "birthday.cake.fill", color: Theme.red))
        }
        if snacks > t.kcal * 0.15 {
            r.less.append(Note(title: "Low-protein snacks", detail: "Chips and crackers add up (\(Int(snacks)) kcal a day). Trade some for yogurt, nuts or cheese.",
                               symbol: "popcorn.fill", color: Theme.red))
        }
        if fatPct > 0.38 {
            r.less.append(Note(title: "Greasy food", detail: "About \(Int(fatPct * 100))% of calories from fat. Fried and fast food slow digestion before training.",
                               symbol: "flame", color: Theme.red))
        }
        if kcal > t.kcal * 1.2 && st.nutritionGoal != .gain {
            r.less.append(Note(title: "Portion sizes", detail: "About \(Int(kcal - t.kcal)) kcal a day over your target. Smaller second helpings.",
                               symbol: "chart.pie.fill", color: Theme.red))
        }

        // Going well
        if protein >= t.protein * 0.9 { r.good.append(Note(title: "Protein on target", detail: "\(Int(protein)) g a day. Nice.", symbol: "checkmark.seal.fill", color: Theme.green)) }
        if produce >= 5 { r.good.append(Note(title: "Plenty of produce", detail: "5+ servings of fruit and veg a day.", symbol: "checkmark.seal.fill", color: Theme.green)) }
        if waterAvg >= Double(st.waterGoal) { r.good.append(Note(title: "Hydrated", detail: "Hitting your water goal.", symbol: "checkmark.seal.fill", color: Theme.green)) }
        if drinkSugar < 30 && r.days >= 3 { r.good.append(Note(title: "Few sugary drinks", detail: "Most of your drinks are water or low sugar.", symbol: "checkmark.seal.fill", color: Theme.green)) }
        return r
    }
}

struct DietNotesCard: View {
    @EnvironmentObject var store: Store
    @State private var open = false

    /// Top few notes for the card: two to eat more of, one to cut, or what's going well.
    static func summary(_ r: DietReport) -> [(DietReport.Note, String, Color)] {
        var out: [(DietReport.Note, String, Color)] = []
        for n in r.more.prefix(2) { out.append((n, "Eat more", Theme.green)) }
        for n in r.less.prefix(1) { out.append((n, "Cut back", Theme.red)) }
        if out.isEmpty { for n in r.good.prefix(2) { out.append((n, "Good", Theme.green)) } }
        return out
    }

    var body: some View {
        let r = DietReport.build(store)
        Button { open = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Overline("Diet notes", color: Theme.green)
                    Spacer()
                    Text(r.days == 0 ? "" : "Last \(r.days) day\(r.days == 1 ? "" : "s")").font(.caption).foregroundStyle(Theme.text3)
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.text3)
                }
                if r.days == 0 {
                    Text("Log a full day or two of food and you'll get notes on what to eat more of, what to cut back on, and foods to try. Today counts once it's over.")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                        .multilineTextAlignment(.leading)
                } else {
                    ForEach(Self.summary(r), id: \.0.id) { n, label, color in
                        HStack(spacing: 10) {
                            Image(systemName: n.symbol).foregroundStyle(n.color).frame(width: 20)
                            Text(n.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                            Spacer()
                            Text(label).font(.caption.weight(.semibold)).foregroundStyle(color)
                        }
                    }
                }
            }
            .cardStyle()
        }
        .buttonStyle(PressableStyle())
        .sheet(isPresented: $open) { DietNotesView().environmentObject(store) }
    }
}

struct DietNotesView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var detail: Food?

    var body: some View {
        let r = DietReport.build(store)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(r.days == 0 ? "Nothing logged in the last week yet. Today counts once it's over." : "Based on the \(r.days) full day\(r.days == 1 ? "" : "s") you logged in the last week.")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                    group("Eat more", r.more, Theme.green)
                    group("Cut back on", r.less, Theme.red)
                    group("Going well", r.good, Theme.green)
                    Text("General sports-nutrition guidance, not medical advice.").font(.caption).foregroundStyle(Theme.text3)
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Diet notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(item: $detail) { f in
                FoodDetailSheet(food: f, meal: Meal.now, date: Date(), existing: nil).environmentObject(store)
            }
        }
    }

    @ViewBuilder
    private func group(_ title: String, _ notes: [DietReport.Note], _ color: Color) -> some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Overline(title, color: color)
                ForEach(notes) { n in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            IconBadge(symbol: n.symbol, color: n.color, size: 32)
                            Text(n.title).font(.headline).foregroundStyle(Theme.text)
                        }
                        Text(n.detail).font(.subheadline).foregroundStyle(Theme.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        let foods = n.foods.compactMap { FoodDB.byID[$0] }
                        if !foods.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(foods) { f in
                                        Button { detail = f } label: { Chip(text: f.name, symbol: f.group.symbol, color: n.color) }
                                            .buttonStyle(PressableStyle())
                                    }
                                }
                            }
                        }
                    }
                    if n.id != notes.last?.id { Divider().overlay(Theme.stroke) }
                }
            }
            .cardStyle()
        }
    }
}
