import SwiftUI
import Charts
import VisionKit

struct FuelView: View {
    @EnvironmentObject var store: Store
    @State private var date = Date()
    @State private var adding: Meal?
    @State private var editing: FoodEntry?
    @State private var detail: Food?
    @State private var loggingWeight = false
    @State private var generating = false
    @State private var showPantry = false
    @State private var showMyFoods = false

    private var isToday: Bool { Day.key(date) == Day.key(Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    dayPicker
                    MacroCard(date: date)
                    if store.data.settings.showMealGenerator {
                        Button { generating = true } label: {
                            HStack(spacing: 12) {
                                IconBadge(symbol: "wand.and.stars", color: Theme.amber, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Meal Generator").font(.headline).foregroundStyle(Theme.text)
                                    Text(store.data.pantry.isEmpty ? "Ideas sized to what's left today" : "From the \(store.data.pantry.count) foods in your pantry")
                                        .font(.caption).foregroundStyle(Theme.text2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.text3)
                            }
                            .cardStyle(padding: 14)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    WaterCard(date: date)
                    DietNotesCard()
                    ForEach(Meal.allCases) { meal in
                        mealSection(meal)
                    }
                    benefitsCard
                    ideas
                    weekChart
                    weightCard
                    Text("Calorie and macro targets are estimates from your profile. Change them in Profile → Nutrition. Not medical advice.")
                        .font(.caption).foregroundStyle(Theme.text3)
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .screenBackground()
            .navigationTitle("Fuel")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = Meal.now } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button { showMyFoods = true } label: { Label("My Foods", systemImage: "tray.full") }
                        Button { showPantry = true } label: { Label("My Pantry", systemImage: "basket") }
                        if store.data.settings.showMealGenerator {
                            Button { generating = true } label: { Label("Meal Generator", systemImage: "wand.and.stars") }
                        }
                    } label: { Image(systemName: "line.3.horizontal.circle").font(.title3) }
                }
            }
            .sheet(item: $adding) { meal in
                AddFoodView(meal: meal, date: date).environmentObject(store)
            }
            .sheet(item: $editing) { entry in
                FoodDetailSheet(food: entry.food, meal: entry.meal, date: date, existing: entry).environmentObject(store)
            }
            .sheet(item: $detail) { food in
                FoodDetailSheet(food: food, meal: Meal.now, date: date, existing: nil).environmentObject(store)
            }
            .sheet(isPresented: $generating) {
                MealGeneratorView(meal: Meal.now, date: date).environmentObject(store)
            }
            .sheet(isPresented: $showPantry) {
                NavigationStack { PantryView() }.environmentObject(store)
            }
            .sheet(isPresented: $showMyFoods) {
                NavigationStack {
                    MyFoodsView().toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showMyFoods = false } } }
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $loggingWeight) {
                WeightSheet().environmentObject(store)
            }
        }
    }

    private var dayPicker: some View {
        HStack {
            RoundIconButton(symbol: "chevron.left", size: 34) { date = Day.add(-1, to: date) }
            Spacer()
            VStack(spacing: 1) {
                Text(isToday ? "Today" : date.formatted(.dateTime.weekday(.wide)))
                    .font(.display(22, .bold)).foregroundStyle(Theme.text)
                Text(date.formatted(.dateTime.month(.wide).day())).font(.caption).foregroundStyle(Theme.text2)
            }
            Spacer()
            RoundIconButton(symbol: "chevron.right", size: 34) { date = Day.add(1, to: date) }
                .opacity(isToday ? 0.3 : 1)
                .disabled(isToday)
        }
    }

    private func mealSection(_ meal: Meal) -> some View {
        let entries = store.foods(on: date).filter { $0.meal == meal }
        let kcal = entries.reduce(0) { $0 + $1.kcal }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: meal.symbol).foregroundStyle(meal.color).font(.system(size: 13, weight: .bold))
                Overline(meal.title)
                Spacer()
                if kcal > 0 { Text("\(Int(kcal)) kcal").font(.number(12, .semibold)).foregroundStyle(Theme.text3) }
                Button { adding = meal } label: {
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold)).foregroundStyle(meal.color)
                        .frame(width: 28, height: 28).background(Circle().fill(meal.color.opacity(0.14)))
                }
                .buttonStyle(PressableStyle())
            }
            if !entries.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, e in
                        Button { editing = e } label: {
                            HStack(spacing: 12) {
                                IconBadge(symbol: e.food.group.symbol, color: meal.color, size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.food.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text).lineLimit(1)
                                    Text(e.food.isDrink ? "\(drinkText(e)) · \(Int(e.protein))g protein" : "\(servingsText(e.servings)) × \(e.food.serving) · \(Int(e.protein))g protein")
                                        .font(.caption).foregroundStyle(Theme.text2).lineLimit(1)
                                }
                                Spacer()
                                Text("\(Int(e.kcal))").font(.number(15)).foregroundStyle(Theme.text)
                            }
                            .padding(.vertical, 7)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { store.removeFood(e.id) } label: { Label("Delete", systemImage: "trash") }
                        }
                        if idx < entries.count - 1 { Divider().overlay(Theme.stroke).padding(.leading, 46) }
                    }
                }
                .cardStyle(padding: 12)
            }
        }
    }

    private var benefitsCard: some View {
        let covered = Set(store.foods(on: date).flatMap(\.food.benefits))
        let key: [FoodBenefit] = [.energy, .recovery, .hydration, .immunity, .antiInflammatory, .bones, .iron, .gut]
        return VStack(alignment: .leading, spacing: 10) {
            Overline("What today's food covers")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(key) { b in
                    let on = covered.contains(b)
                    HStack(spacing: 6) {
                        Image(systemName: on ? "checkmark.circle.fill" : b.symbol).font(.system(size: 12, weight: .bold))
                        Text(b.title).font(.system(size: 13, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(on ? Theme.bg : b.color)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(on ? b.color : b.color.opacity(0.1)))
                }
            }
            if let missing = key.first(where: { !covered.contains($0) }) {
                Text("Missing \(missing.title.lowercased()): \(missing.detail)").font(.caption).foregroundStyle(Theme.text2)
            }
        }
        .cardStyle()
    }

    private var ideas: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Fuel ideas", subtitle: "Tap to add")
            ForEach([Meal.preGame, .postWorkout, .snack], id: \.self) { meal in
                VStack(alignment: .leading, spacing: 6) {
                    Overline(meal == .preGame ? "Before games & practice" : (meal == .postWorkout ? "After training" : "Smart snacks"), color: meal.color)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(FoodDB.ideas(meal)) { food in
                                Button { detail = food } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(food.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Spacer(minLength: 0)
                                        Text("\(Int(food.kcal)) kcal · \(Int(food.protein))g P").font(.caption2).foregroundStyle(Theme.text2)
                                    }
                                    .padding(10)
                                    .frame(width: 130, height: 76, alignment: .topLeading)
                                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(meal.color.opacity(0.1)))
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, -16)
                }
            }
        }
    }

    private struct DayKcal: Identifiable {
        let date: Date
        let kcal: Double
        let protein: Double
        var id: Date { date }
    }

    private var weekChart: some View {
        let days: [DayKcal] = (0..<7).reversed().map { back in
            let d = Day.add(-back, to: Day.start(date))
            let t = store.totals(on: d)
            return DayKcal(date: d, kcal: t.kcal, protein: t.protein)
        }
        let target = store.targets.kcal
        return VStack(alignment: .leading, spacing: 10) {
            Overline("Last 7 days")
            Chart {
                ForEach(days) { d in
                    BarMark(x: .value("Day", d.date, unit: .day), y: .value("kcal", d.kcal))
                        .foregroundStyle(Theme.amber.opacity(0.8))
                        .cornerRadius(4)
                }
                RuleMark(y: .value("Target", target))
                    .foregroundStyle(Theme.text3)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true).foregroundStyle(Theme.text3)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Theme.stroke)
                    AxisValueLabel().foregroundStyle(Theme.text3)
                }
            }
            .frame(height: 140)
        }
        .cardStyle()
    }

    private var weightCard: some View {
        let entries = store.data.daily.compactMap { pair -> (Date, Double)? in
            guard let w = pair.value.weightKg, let d = Day.parse(pair.key) else { return nil }
            return (d, w)
        }
        .sorted { $0.0 < $1.0 }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Overline("Body weight")
                    Text(entries.last.map { store.weightText($0.1) } ?? "—").font(.number(26)).foregroundStyle(Theme.text)
                }
                Spacer()
                Button { loggingWeight = true } label: { Label("Log", systemImage: "plus") }
                    .buttonStyle(MiniPillStyle(color: Theme.ice))
            }
            if entries.count >= 2 {
                Chart {
                    ForEach(entries.indices, id: \.self) { i in
                        LineMark(x: .value("Date", entries[i].0), y: .value("Weight", entries[i].1))
                            .foregroundStyle(Theme.ice)
                            .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis(.hidden)
                .frame(height: 70)
            }
        }
        .cardStyle()
    }

    private func servingsText(_ v: Double) -> String { AmountField.format(v) }

    private func drinkText(_ e: FoodEntry) -> String {
        let oz = e.servings * (e.food.servingOz ?? 8)
        return store.data.settings.units == .imperial ? "\(Int(oz.rounded())) oz" : "\(Int((oz * 29.5735).rounded())) ml"
    }
}

// MARK: - Cards

struct MacroCard: View {
    @EnvironmentObject var store: Store
    let date: Date

    var body: some View {
        let t = store.totals(on: date)
        let target = store.targets
        let left = target.kcal - t.kcal
        HStack(spacing: 18) {
            ZStack {
                Ring(progress: t.kcal / max(1, target.kcal), color: t.kcal > target.kcal * 1.1 ? Theme.red : Theme.amber, lineWidth: 12)
                VStack(spacing: 0) {
                    Text("\(Int(abs(left)))").font(.number(26)).foregroundStyle(Theme.text)
                    Text(left >= 0 ? "kcal left" : "kcal over").font(.caption2.weight(.semibold)).foregroundStyle(Theme.text2)
                }
            }
            .frame(width: 118, height: 118)
            VStack(alignment: .leading, spacing: 10) {
                macro("Protein", t.protein, target.protein, Theme.green)
                macro("Carbs", t.carbs, target.carbs, Theme.amber)
                macro("Fat", t.fat, target.fat, Theme.ice)
            }
        }
        .cardStyle()
    }

    private func macro(_ name: String, _ v: Double, _ goal: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).font(.caption.weight(.bold)).foregroundStyle(Theme.text2)
                Spacer()
                Text("\(Int(v)) / \(Int(goal))g").font(.number(12, .semibold)).foregroundStyle(Theme.text)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule().fill(color).frame(width: max(4, geo.size.width * min(1, v / max(1, goal))))
                }
            }
            .frame(height: 6)
        }
    }
}

struct WaterCard: View {
    @EnvironmentObject var store: Store
    let date: Date

    var body: some View {
        let glasses = store.daily(date).water
        let goal = max(1, store.data.settings.waterGoal)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Overline("Water", color: Theme.ice)
                Spacer()
                Text("\(glasses) / \(goal) glasses").font(.number(13, .semibold)).foregroundStyle(Theme.text)
            }
            HStack(spacing: 6) {
                ForEach(0..<max(goal, glasses), id: \.self) { i in
                    Button {
                        store.updateDaily(date) { $0.water = i < glasses ? i : i + 1 }
                        store.haptic(.light)
                    } label: {
                        Image(systemName: i < glasses ? "drop.fill" : "drop")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(i < glasses ? Theme.ice : Theme.text3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 30)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Add food

struct AddFoodView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var meal: Meal
    let date: Date

    @State private var query = ""
    @State private var online: [Food] = []
    @State private var searching = false
    @State private var searchedFor = ""
    @State private var selected: Food?
    @State private var quickAdd = false
    @State private var group: FoodGroup?

    private var local: [Food] {
        let all = store.searchFoods(query)
        return group.map { g in all.filter { $0.group == g } } ?? all
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Meal", selection: $meal) {
                        ForEach(Meal.allCases) { Label($0.title, systemImage: $0.symbol).tag($0) }
                    }
                    ScanButtons { food in selected = food }
                    Button { quickAdd = true } label: { Label("Quick add", systemImage: "square.and.pencil") }
                }
                .listRowBackground(Theme.surface)

                if query.isEmpty && !store.data.customFoods.isEmpty {
                    Section("My foods") {
                        ForEach(store.data.customFoods.prefix(20)) { row($0) }
                    }
                    .listRowBackground(Theme.surface)
                }

                if query.isEmpty && !store.recentFoods.isEmpty {
                    Section("Recent") {
                        ForEach(store.recentFoods) { row($0) }
                    }
                    .listRowBackground(Theme.surface)
                }

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(FoodGroup.allCases) { g in
                                Button { group = group == g ? nil : g } label: {
                                    Chip(text: g.title, symbol: g.symbol, color: Theme.ice, filled: group == g)
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    ForEach(local.prefix(80)) { row($0) }
                } header: { Text(query.isEmpty ? "Food list" : "Matches") }
                .listRowBackground(Theme.surface)

                if !query.isEmpty {
                    Section {
                        if searching {
                            HStack { ProgressView(); Text("Searching Open Food Facts…").foregroundStyle(Theme.text2) }
                        } else if searchedFor == query {
                            if online.isEmpty { Text("No online results.").foregroundStyle(Theme.text2) }
                            ForEach(online) { row($0) }
                        } else {
                            Button { Task { await runOnline() } } label: {
                                Label("Search brands & packaged foods for \"\(query)\"", systemImage: "globe")
                            }
                        }
                    } header: { Text("Online") } footer: { Text("Packaged foods from Open Food Facts. Values per serving where listed, otherwise per 100 g.") }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .screenBackground()
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search foods")
            .onSubmit(of: .search) { Task { await runOnline() } }
            .navigationTitle("Add food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(item: $selected) { food in
                FoodDetailSheet(food: food, meal: meal, date: date, existing: nil) { dismiss() }
                    .environmentObject(store)
            }
            .sheet(isPresented: $quickAdd) {
                QuickAddFood(meal: meal, date: date) { dismiss() }.environmentObject(store)
            }
        }
    }

    private func runOnline() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        searching = true
        online = await FoodAPI.search(q)
        searchedFor = query
        searching = false
    }

    private func row(_ food: Food) -> some View {
        Button { selected = food } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(food.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text).lineLimit(1)
                        if store.data.favoriteFoods.contains(food.id) {
                            Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(Theme.amber)
                        }
                    }
                    Text("\(food.serving) · P \(Int(food.protein)) · C \(Int(food.carbs)) · F \(Int(food.fat))")
                        .font(.caption).foregroundStyle(Theme.text2).lineLimit(1)
                }
                Spacer()
                HStack(spacing: 3) {
                    ForEach(food.benefits.prefix(3)) { b in
                        Image(systemName: b.symbol).font(.system(size: 10, weight: .bold)).foregroundStyle(b.color)
                    }
                }
                Text("\(Int(food.kcal))").font(.number(15)).foregroundStyle(Theme.text).frame(minWidth: 36, alignment: .trailing)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FoodDetailSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var food: Food
    @State var meal: Meal
    let date: Date
    let existing: FoodEntry?
    var onDone: (() -> Void)? = nil
    @State private var servings: Double = 1
    @State private var customizing = false

    private var imperial: Bool { store.data.settings.units == .imperial }
    private var ozPerServing: Double { food.servingOz ?? 8 }
    /// Drinks are picked by volume; this maps it onto servings.
    private var volume: Binding<Double> {
        Binding(get: { (servings * ozPerServing * (imperial ? 1 : 29.5735)).rounded() },
                set: { servings = max(0.05, $0 / (imperial ? 1 : 29.5735) / ozPerServing) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Overline(food.group.title, color: Theme.amber)
                        Text(food.name).font(.display(28)).foregroundStyle(Theme.text)
                        Text("1 serving = \(food.serving) · \(food.source)").font(.footnote).foregroundStyle(Theme.text2)
                    }
                    HStack(spacing: 10) {
                        stat("\(Int(food.kcal * servings))", "kcal", Theme.amber)
                        stat(fmt(food.protein * servings), "protein", Theme.green)
                        stat(fmt(food.carbs * servings), "carbs", Theme.amber)
                        stat(fmt(food.fat * servings), "fat", Theme.ice)
                    }
                    if food.isDrink {
                        drinkAmount
                    } else {
                        HStack {
                            Text("Servings").font(.headline).foregroundStyle(Theme.text)
                            Spacer()
                            AmountField(value: $servings, step: 0.25, range: 0.1...50)
                        }
                        .cardStyle(padding: 14)
                    }
                    Picker("Meal", selection: $meal) {
                        ForEach(Meal.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .cardStyle(padding: 10)
                    if !food.benefits.isEmpty || !food.note.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Overline("What it helps")
                            if !food.note.isEmpty { Text(food.note).font(.subheadline).foregroundStyle(Theme.text) }
                            ForEach(food.benefits) { b in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: b.symbol).foregroundStyle(b.color).frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(b.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                                        Text(b.detail).font(.caption).foregroundStyle(Theme.text2)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }
                    if food.fiber > 0 {
                        Text("Fiber \(fmt(food.fiber * servings)) g").font(.caption).foregroundStyle(Theme.text3)
                    }
                    Button { customizing = true } label: {
                        Label(store.data.customFoods.contains { $0.id == food.id } ? "Edit this food" : "Customize & save as my own",
                              systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.amber))
                    Button {
                        if let existing {
                            store.removeFood(existing.id)
                        }
                        store.addFood(food, servings: servings, meal: meal, date: existing?.date ?? date)
                        dismiss()
                        onDone?()
                    } label: { Label(existing == nil ? "Add to \(meal.title)" : "Save", systemImage: "checkmark") }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.green))
                    if let existing {
                        Button("Delete", role: .destructive) { store.removeFood(existing.id); dismiss() }
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(16)
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if store.data.favoriteFoods.contains(food.id) { store.data.favoriteFoods.remove(food.id) } else { store.data.favoriteFoods.insert(food.id) }
                        if food.source != "Edgework", !store.data.customFoods.contains(where: { $0.id == food.id }) { store.data.customFoods.append(food) }
                    } label: {
                        Image(systemName: store.data.favoriteFoods.contains(food.id) ? "star.fill" : "star")
                            .foregroundStyle(Theme.amber)
                    }
                }
            }
            .onAppear {
                if let existing { servings = existing.servings }
                if existing == nil && food.isDrink && meal != .preGame && meal != .postWorkout { meal = .drinks }
            }
            .sheet(isPresented: $customizing) {
                FoodEditor(food: food, editingSaved: store.data.customFoods.contains { $0.id == food.id }) { food = $0 }
                    .environmentObject(store)
            }
        }
        .presentationDetents([.large])
    }

    private var drinkAmount: some View {
        let presets: [Double] = imperial ? [8, 12, 16, 20, 32] : [250, 330, 500, 750, 1000]
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How much").font(.headline).foregroundStyle(Theme.text)
                Spacer()
                AmountField(value: volume, step: imperial ? 4 : 50, range: 1...(imperial ? 128 : 4000), unit: imperial ? "oz" : "ml")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(presets, id: \.self) { p in
                        Button { volume.wrappedValue = p } label: {
                            Chip(text: "\(Int(p)) \(imperial ? "oz" : "ml")", color: Theme.ice, filled: abs(volume.wrappedValue - p) < 0.5)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
            if food.hydrates {
                Label("Counts toward water: +\(max(1, Int((servings * ozPerServing / 8).rounded()))) glass\(Int((servings * ozPerServing / 8).rounded()) == 1 ? "" : "es")",
                      systemImage: "drop.fill")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Theme.ice)
            } else if food.sugaryDrink {
                Label("\(Int(food.carbs * servings)) g of sugar you drink. Water or zero-sugar electrolytes hydrate without it.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote).foregroundStyle(Theme.amber)
            } else if food.id == "sports-drink" {
                Label("Best during long practices, tournaments and hot days.", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(Theme.text2)
            }
        }
        .cardStyle(padding: 14)
    }

    private func stat(_ v: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.number(20)).foregroundStyle(Theme.text)
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
    }

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v)
    }
}

struct QuickAddFood: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    let date: Date
    var onDone: () -> Void
    @State private var name = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var save = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    field("Calories", $kcal)
                    field("Protein (g)", $protein)
                    field("Carbs (g)", $carbs)
                    field("Fat (g)", $fat)
                    Toggle("Save to my foods", isOn: $save)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Quick add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let food = Food(id: "custom-\(UUID().uuidString)", name: name.isEmpty ? "Quick add" : name, group: .meal,
                                        serving: "1 serving", kcal: num(kcal), protein: num(protein), carbs: num(carbs), fat: num(fat),
                                        source: "My foods")
                        if save { store.data.customFoods.append(food) }
                        store.addFood(food, servings: 1, meal: meal, date: date)
                        dismiss()
                        onDone()
                    }
                    .fontWeight(.bold)
                    .disabled(kcal.isEmpty)
                }
            }
        }
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
        }
    }

    private func num(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }
}

struct WeightSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Weight", text: $text).keyboardType(.decimalPad).font(.number(28))
                        Text(store.data.settings.units == .imperial ? "lb" : "kg").foregroundStyle(Theme.text2)
                    }
                } footer: { Text("Weigh in the morning for consistent numbers. This also updates your nutrition targets.") }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(text.replacingOccurrences(of: ",", with: ".")), v > 0 {
                            let kg = store.data.settings.units == .imperial ? v / 2.20462 : v
                            store.updateDaily { $0.weightKg = kg }
                            store.data.settings.weightKg = kg
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Barcode scanner

struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    let onCode: (String) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            BarcodeScanner(onCode: onCode).ignoresSafeArea()
            HStack {
                Text("Point at a barcode").font(.headline).foregroundStyle(.white)
                Spacer()
                RoundIconButton(symbol: "xmark", size: 36) { dismiss() }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

struct BarcodeScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.barcode()], qualityLevel: .balanced,
                                           recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false,
                                           isHighlightingEnabled: true)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {
        if !vc.isScanning { try? vc.startScanning() }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        private var done = false

        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !done else { return }
            for item in addedItems {
                if case .barcode(let code) = item, let value = code.payloadStringValue {
                    done = true
                    dataScanner.stopScanning()
                    onCode(value)
                    return
                }
            }
        }
    }
}
