import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var store: Store
    let exercise: Exercise
    @State private var addedTo: String?

    private var sampleItem: WorkoutItem {
        WorkoutItem(exerciseID: exercise.id, sets: exercise.sets, base: exercise.base, rest: exercise.category.defaultRest, block: .main)
    }

    var body: some View {
        let ex = exercise
        let color = ex.category.color
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero(ex, color)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(text: ex.levelTitle, symbol: "chart.bar.fill", color: color)
                        if ex.equipment.isEmpty {
                            Chip(text: "No equipment", symbol: "figure.stand", color: Theme.text2)
                        }
                        ForEach(ex.equipment) { e in
                            Chip(text: e.title, symbol: e.symbol, color: store.data.settings.equipment.contains(e) ? Theme.text2 : Theme.red)
                        }
                        if ex.perSide { Chip(text: "Each side", symbol: "arrow.left.and.right", color: Theme.text2) }
                        if ex.tags.contains(.injuryPrevention) { Chip(text: "Injury prevention", symbol: "cross.case.fill", color: Theme.green) }
                        if ex.tags.contains(.explosive) { Chip(text: "Explosive", symbol: "bolt.fill", color: Theme.red) }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16)

                targetCard(ex, color)
                planCard(ex, color)

                VStack(alignment: .leading, spacing: 14) {
                    Overline("Muscles worked")
                    BodyMapPair(intensity: { m in ex.primary.contains(m) ? 1 : (ex.secondary.contains(m) ? 0.35 : 0) }, color: color)
                        .frame(height: 230)
                    HStack(alignment: .top, spacing: 20) {
                        legend("Primary", ex.primary, color.opacity(1))
                        if !ex.secondary.isEmpty { legend("Secondary", ex.secondary, color.opacity(0.5)) }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 14) {
                    Overline("How to do it")
                    ForEach(Array(ex.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.number(14))
                                .foregroundStyle(Theme.bg)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(color))
                            Text(step).font(.body).foregroundStyle(Theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Overline("Coaching cues")
                    ForEach(ex.cues, id: \.self) { cue in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(color)
                            Text(cue).foregroundStyle(Theme.text)
                        }
                        .font(.subheadline)
                    }
                }
                .cardStyle()

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "figure.hockey").font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.ice)
                    VStack(alignment: .leading, spacing: 4) {
                        Overline("Why it helps", color: Theme.ice)
                        Text(ex.why).font(.subheadline).foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).fill(Theme.ice.opacity(0.08)))
                .overlay(alignment: .leading) {
                    Capsule().fill(Theme.ice).frame(width: 3).padding(.vertical, 14)
                }

                let history = store.timesPerformed(ex.id)
                if history.count > 0 {
                    HStack {
                        StatTile(value: "\(history.count)", label: "Times done", symbol: "checkmark.seal.fill", color: Theme.green)
                        StatTile(value: history.last.map { $0.formatted(.dateTime.month(.abbreviated).day()) } ?? "—", label: "Last done", symbol: "calendar", color: Theme.ice)
                    }
                }

                Button {
                    store.start(Workout(title: ex.name, subtitle: ex.summary, focus: .custom,
                                        items: [store.item(for: ex, block: .main)]))
                } label: { Label("Do just this one", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle(color: color))
                    .padding(.bottom, 20)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    if store.data.custom.isEmpty {
                        Text("No custom workouts yet")
                    }
                    ForEach(store.data.custom) { w in
                        Button(w.title) {
                            store.add(exercise, to: w.id)
                            addedTo = w.title
                        }
                    }
                    Divider()
                    Button {
                        let w = Workout(title: exercise.name, subtitle: "", focus: .custom,
                                        items: [store.item(for: exercise, block: .main)])
                        store.saveCustom(w)
                        addedTo = w.title
                    } label: { Label("New workout with this", systemImage: "plus") }
                } label: { Image(systemName: "text.badge.plus") }
                Button { store.toggleFavorite(ex.id) } label: {
                    Image(systemName: store.isFavorite(ex.id) ? "star.fill" : "star")
                        .foregroundStyle(store.isFavorite(ex.id) ? Theme.amber : Theme.text)
                }
            }
        }
        .alert("Added", isPresented: Binding(get: { addedTo != nil }, set: { if !$0 { addedTo = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text("Added to \(addedTo ?? "")") }
    }

    private func hero(_ ex: Exercise, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FigureView(exercise: ex)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .padding(.top, 8)
            Overline(ex.category.title, color: color)
            Text(ex.name).font(.display(32)).foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(ex.summary).font(.subheadline).foregroundStyle(Theme.text2)
            DemoVideoLink(exercise: ex, color: color).padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [color.opacity(0.22), color.opacity(0.03)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(color.opacity(0.25)))
    }

    private func targetCard(_ ex: Exercise, _ color: Color) -> some View {
        let item = sampleItem
        let f = store.factor(ex.id)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("Your target")
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(ex.sets) ×").font(.number(22)).foregroundStyle(Theme.text2)
                        Text(store.targetText(item)).font(.number(34)).foregroundStyle(Theme.text)
                            .contentTransition(.numericText())
                        if store.measure(of: ex.id) == .reps { Text(Library.isHill(ex) ? "trips up & down" : "reps").font(.subheadline).foregroundStyle(Theme.text2) }
                        if ex.perSide { Text("/ side").font(.subheadline).foregroundStyle(Theme.text2) }
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                    RoundIconButton(symbol: "minus", size: 40) { withAnimation { store.adjust(item, up: false) } }
                    RoundIconButton(symbol: "plus", size: 40) { withAnimation { store.adjust(item, up: true) } }
                }
            }
            HStack {
                Text("Default \(ex.defaultTarget()) · personal \(Int((f * 100).rounded()))% · global \(Int((store.intensity * 100).rounded()))%")
                    .font(.caption).foregroundStyle(Theme.text3)
                Spacer()
                if abs(f - 1) > 0.001 {
                    Button("Reset") { withAnimation { store.resetFactor(ex.id) } }
                        .font(.caption.weight(.bold)).foregroundStyle(color)
                }
            }
            if Library.travelIDs.contains(ex.id) {
                Picker("Count", selection: Binding(
                    get: { store.data.settings.measureModes[ex.id] ?? "global" },
                    set: { v in store.data.settings.measureModes[ex.id] = v == "global" ? nil : v })) {
                    Text("Global (\(store.data.settings.lineMode ? "lines" : (ex.measure == .seconds ? "time" : "reps")))").tag("global")
                    Text("Lines").tag("lines")
                    Text(ex.measure == .seconds ? "Time" : "Reps").tag("default")
                }
                .pickerStyle(.segmented)
            }
        }
        .cardStyle()
    }

    /// How often this shows up in generated workouts: priority, required, or never.
    private func planCard(_ ex: Exercise, _ color: Color) -> some View {
        let p = store.priority(ex.id)
        let required = store.isRequired(ex.id)
        let excluded = store.data.settings.excluded.contains(ex.id)
        return VStack(alignment: .leading, spacing: 12) {
            Overline("In my workouts")
            VStack(alignment: .leading, spacing: 6) {
                Text("Priority").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                PriorityPicker(value: Binding(get: { p }, set: { store.setPriority(ex.id, $0); store.haptic(.light) }))
                    .disabled(excluded)
                    .opacity(excluded ? 0.4 : 1)
                Text(Store.priorityDetail(p, category: ex.category.title.lowercased()))
                    .font(.caption).foregroundStyle(Theme.text3)
            }
            Divider().overlay(Theme.stroke)
            Toggle(isOn: Binding(get: { required }, set: { store.setRequired(ex, $0); store.haptic(.medium) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Required in every workout").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                    Text(required ? "Added to every generated workout. Change sets in Library › Required." : "Like a mandatory run or 100 shots.")
                        .font(.caption).foregroundStyle(Theme.text3)
                }
            }
            .tint(color)
            Toggle(isOn: Binding(get: { excluded }, set: { on in
                if on { store.data.settings.excluded.insert(ex.id); store.setPriority(ex.id, 0); store.setRequired(ex, false) }
                else { store.data.settings.excluded.remove(ex.id) }
            })) {
                Text("Never show me this").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
            }
            .tint(Theme.red)
        }
        .cardStyle()
    }

    private func legend(_ title: String, _ muscles: [Muscle], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
                Text(title).font(.caption.weight(.bold)).foregroundStyle(Theme.text2)
            }
            ForEach(muscles) { m in
                Text(m.title).font(.subheadline).foregroundStyle(Theme.text)
            }
        }
    }
}
