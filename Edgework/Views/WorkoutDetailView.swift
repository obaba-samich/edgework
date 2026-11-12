import SwiftUI

/// Shared editor/preview for any workout. Edits go through the binding.
struct WorkoutDetailView: View {
    @EnvironmentObject var store: Store
    @Binding var workout: Workout
    var onRegenerate: (() -> Void)? = nil
    @State private var showPicker = false
    @State private var swapFailed = false
    @State private var reordering = false

    var body: some View {
        if reordering { reorderList } else { mainContent }
    }

    private var reorderList: some View {
        List {
            ForEach(workout.ordered) { item in
                if let ex = item.exercise {
                    HStack(spacing: 12) {
                        IconBadge(symbol: ex.symbol, color: ex.category.color, size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                            Text(item.block.title).font(.caption).foregroundStyle(Theme.text2)
                        }
                        Spacer()
                        Text("\(item.sets)×\(store.targetText(item))").font(.number(13)).foregroundStyle(Theme.text2)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .onMove { from, to in
                var list = workout.ordered
                guard let src = from.first else { return }
                let id = list[src].id
                list.move(fromOffsets: from, toOffset: to)
                // A moved item keeps its block if it still borders it, otherwise joins its new neighbours.
                if let i = list.firstIndex(where: { $0.id == id }) {
                    let above: Block? = i > 0 ? list[i - 1].block : nil
                    let below: Block? = i + 1 < list.count ? list[i + 1].block : nil
                    let orig = list[i].block
                    if orig != above && orig != below { list[i].block = above ?? below ?? orig }
                }
                workout.items = list
            }
            .onDelete { idx in
                let ids = idx.map { workout.ordered[$0].id }
                workout.items.removeAll { ids.contains($0.id) }
            }
        }
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
        .screenBackground()
        .safeAreaInset(edge: .bottom) {
            Button { withAnimation { reordering = false } } label: { Label("Done reordering", systemImage: "checkmark") }
                .buttonStyle(PrimaryButtonStyle())
                .padding(16)
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                globalRow
                ForEach(Block.allCases) { block in
                    let items = workout.items.filter { $0.block == block && $0.exercise != nil }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Overline(block.title)
                                Spacer()
                                Text("~\(max(1, items.map(store.estimateSeconds).reduce(0, +) / 60)) min")
                                    .font(.number(12, .semibold)).foregroundStyle(Theme.text3)
                            }
                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                                    ItemRow(item: item,
                                            onSwap: { swap(item) },
                                            onRemove: { remove(item) },
                                            onSets: { delta in changeSets(item, delta) },
                                            onMove: { up in move(item, up: up) })
                                    if idx < items.count - 1 {
                                        Divider().overlay(Theme.stroke).padding(.leading, 56)
                                    }
                                }
                            }
                            .cardStyle(padding: 12)
                        }
                    }
                }
                Button { showPicker = true } label: {
                    Label("Add exercise", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.ice))
                Text("Long-press a row or use ··· to swap, reorder or change sets. − / + changes that exercise's reps everywhere, from now on.")
                    .font(.caption).foregroundStyle(Theme.text3)
                    .padding(.bottom, 90)
            }
            .padding(16)
        }
        .screenBackground()
        .safeAreaInset(edge: .bottom) {
            Button { store.start(workout) } label: {
                Label("Start workout", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle(color: workout.focus.color))
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg], startPoint: .top, endPoint: .center).ignoresSafeArea())
        }
        .sheet(isPresented: $showPicker) {
            ExercisePicker { picked in
                for ex in picked {
                    workout.items.append(store.item(for: ex, block: ex.category == .warmup ? .warmup : (ex.tags.contains(.cooldown) && ex.category == .mobility ? .cooldown : .main)))
                }
            }
            .environmentObject(store)
        }
        .alert("No swap available", isPresented: $swapFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Nothing else in this category matches your equipment. Add more gear in Profile.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chip(text: workout.focus.shortTitle, symbol: workout.focus.symbol, color: workout.focus.color)
            Text(workout.title).font(.display(32)).foregroundStyle(Theme.text)
            if !workout.subtitle.isEmpty {
                Text(workout.subtitle).font(.subheadline).foregroundStyle(Theme.text2)
            }
            HStack(spacing: 10) {
                StatTile(value: "\(store.estimateMinutes(workout))", label: "Minutes", symbol: "clock.fill", color: workout.focus.color)
                StatTile(value: "\(workout.items.count)", label: "Exercises", symbol: "list.bullet", color: workout.focus.color)
                StatTile(value: "\(workout.totalSets)", label: "Sets", symbol: "square.stack.fill", color: workout.focus.color)
            }
            CompositionBar(categories: workout.mainCategories)
                .padding(.top, 2)
            HStack(spacing: 8) {
                Button { withAnimation { reordering = true } } label: {
                    Chip(text: "Reorder", symbol: "arrow.up.arrow.down", color: Theme.ice)
                }
                Menu {
                    Button { refresh([.main, .finisher]) } label: { Label("New main exercises", systemImage: "arrow.triangle.2.circlepath") }
                    Button { refresh([.warmup, .stretch]) } label: { Label("New warm-up & stretches", systemImage: "flame") }
                    Button { refresh([.cooldown]) } label: { Label("New cool-down", systemImage: "leaf") }
                    if let onRegenerate {
                        Divider()
                        Button { withAnimation { onRegenerate() } } label: { Label("Generate a whole new workout", systemImage: "dice") }
                    }
                } label: {
                    Chip(text: "Refresh", symbol: "arrow.triangle.2.circlepath", color: Theme.amber)
                }
                Button { showPicker = true } label: {
                    Chip(text: "Add", symbol: "plus", color: Theme.green)
                }
                Spacer()
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 4)
        }
    }

    private var globalRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Everything").font(.headline).foregroundStyle(Theme.text)
                Text("Scales all exercises at once").font(.caption).foregroundStyle(Theme.text2)
            }
            Spacer()
            TargetStepper(value: "\(Int((store.intensity * 100).rounded()))%",
                          tint: store.intensity == 1 ? Theme.text : (store.intensity < 1 ? Theme.ice : Theme.amber),
                          minus: { store.adjustAll(up: false) },
                          plus: { store.adjustAll(up: true) })
        }
        .cardStyle(padding: 14)
    }

    private func index(_ item: WorkoutItem) -> Int? { workout.items.firstIndex { $0.id == item.id } }

    private func swap(_ item: WorkoutItem) {
        guard let i = index(item) else { return }
        if let new = Generator.swap(item, in: workout, settings: store.data.settings) {
            withAnimation(.snappy) { workout.items[i] = new }
            store.haptic(.medium)
        } else {
            swapFailed = true
        }
    }

    private func refresh(_ blocks: Set<Block>) {
        var w = workout
        for i in w.items.indices where blocks.contains(w.items[i].block) {
            if let new = Generator.swap(w.items[i], in: w, settings: store.data.settings) { w.items[i] = new }
        }
        withAnimation(.snappy) { workout = w }
        store.haptic(.medium)
    }

    private func remove(_ item: WorkoutItem) {
        guard let i = index(item) else { return }
        _ = withAnimation(.snappy) { workout.items.remove(at: i) }
    }

    private func changeSets(_ item: WorkoutItem, _ delta: Int) {
        guard let i = index(item) else { return }
        workout.items[i].sets = (workout.items[i].sets + delta).clamped(1, 12)
        store.haptic(.light)
    }

    private func move(_ item: WorkoutItem, up: Bool) {
        let sameBlock = workout.items.indices.filter { workout.items[$0].block == item.block }
        guard let pos = sameBlock.firstIndex(where: { workout.items[$0].id == item.id }) else { return }
        let target = up ? pos - 1 : pos + 1
        guard sameBlock.indices.contains(target) else { return }
        withAnimation(.snappy) { workout.items.swapAt(sameBlock[pos], sameBlock[target]) }
    }
}

struct ItemRow: View {
    @EnvironmentObject var store: Store
    let item: WorkoutItem
    let onSwap: () -> Void
    let onRemove: () -> Void
    let onSets: (Int) -> Void
    let onMove: (Bool) -> Void

    var body: some View {
        if let ex = item.exercise {
            let f = store.factor(ex.id)
            HStack(spacing: 12) {
                NavigationLink {
                    ExerciseDetailView(exercise: ex)
                } label: {
                    HStack(spacing: 12) {
                        IconBadge(symbol: ex.symbol, color: ex.category.color, size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ex.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.text)
                                .lineLimit(2).multilineTextAlignment(.leading)
                            HStack(spacing: 6) {
                                Text("\(item.sets) \(item.sets == 1 ? "set" : "sets")\(ex.perSide ? " · each side" : "")")
                                if abs(f - 1) > 0.001 && !item.fixed {
                                    Text("\(f > 1 ? "+" : "")\(Int(((f - 1) * 100).rounded()))%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(f > 1 ? Theme.amber : Theme.ice)
                                        .padding(.horizontal, 5).padding(.vertical, 1)
                                        .background(Capsule().fill((f > 1 ? Theme.amber : Theme.ice).opacity(0.14)))
                                }
                            }
                            .font(.footnote).foregroundStyle(Theme.text2)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                TargetStepper(value: store.targetText(item), unit: ex.measure == .reps ? ex.measure.label(store.target(item)) : nil,
                              minus: { withAnimation(.snappy) { store.adjust(item, up: false) } },
                              plus: { withAnimation(.snappy) { store.adjust(item, up: true) } })

                Menu {
                    menuItems
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.text2)
                        .frame(width: 24, height: 34)
                        .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 8)
            .contextMenu { menuItems }
        }
    }

    @ViewBuilder private var menuItems: some View {
        Button { onSwap() } label: { Label("Swap exercise", systemImage: "arrow.triangle.2.circlepath") }
        Button { onSets(1) } label: { Label("Add a set", systemImage: "plus.square") }
        Button { onSets(-1) } label: { Label("Remove a set", systemImage: "minus.square") }
        Button { onMove(true) } label: { Label("Move up", systemImage: "arrow.up") }
        Button { onMove(false) } label: { Label("Move down", systemImage: "arrow.down") }
        if abs(store.factor(item.exerciseID) - 1) > 0.001 {
            Button { store.resetFactor(item.exerciseID) } label: { Label("Reset reps to default", systemImage: "arrow.uturn.backward") }
        }
        Divider()
        Button(role: .destructive) { onRemove() } label: { Label("Remove", systemImage: "trash") }
    }
}

// MARK: - Screens wrapping the detail view

struct TodayWorkoutScreen: View {
    @EnvironmentObject var store: Store
    @State private var saved = false

    var body: some View {
        WorkoutDetailView(workout: store.todayWorkout, onRegenerate: { store.reroll() })
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { withAnimation { store.reroll() } } label: { Image(systemName: "dice") }
                    Menu {
                        Button {
                            var w = store.todayWorkout.wrappedValue
                            w.id = UUID()
                            w.title = "\(w.title) (\(Date().formatted(.dateTime.month(.abbreviated).day())))"
                            store.saveCustom(w)
                            saved = true
                        } label: { Label("Save to My Workouts", systemImage: "square.and.arrow.down") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .alert("Saved", isPresented: $saved) { Button("OK", role: .cancel) {} } message: {
                Text("Find it under Train → My Workouts.")
            }
    }
}

struct ProgramScreen: View {
    @EnvironmentObject var store: Store
    let program: Program
    @State private var workout: Workout?
    @State private var saved = false

    var body: some View {
        WorkoutDetailView(workout: Binding(get: { workout ?? store.programWorkout(program) },
                                           set: { workout = $0 }))
            .navigationTitle(program.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        var w = workout ?? store.programWorkout(program)
                        w.id = UUID()
                        store.saveCustom(w)
                        saved = true
                    } label: { Image(systemName: "square.and.arrow.down") }
                }
            }
            .alert("Saved to My Workouts", isPresented: $saved) { Button("OK", role: .cancel) {} }
    }
}

struct CustomWorkoutScreen: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var editing = false
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let i = store.data.custom.firstIndex(where: { $0.id == id }) {
                WorkoutDetailView(workout: $store.data.custom[i])
                    .navigationTitle(store.data.custom[i].title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button { editing = true } label: { Label("Edit name & details", systemImage: "pencil") }
                                Button {
                                    var copy = store.data.custom[i]
                                    copy.id = UUID()
                                    copy.title += " copy"
                                    store.saveCustom(copy)
                                } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                                Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                            } label: { Image(systemName: "ellipsis.circle") }
                        }
                    }
                    .sheet(isPresented: $editing) {
                        BuilderView(workout: store.data.custom[i]) { store.saveCustom($0) }
                            .environmentObject(store)
                    }
                    .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            dismiss()
                            store.data.custom.removeAll { $0.id == id }
                        }
                    }
            } else {
                EmptyState(symbol: "questionmark.folder", title: "Workout not found", message: "It may have been deleted.")
                    .padding()
                    .screenBackground()
            }
        }
    }
}

struct GeneratedScreen: View {
    @EnvironmentObject var store: Store
    let focus: Focus
    let minutes: Int
    @State private var seed = Int.random(in: 1...999_999)
    @State private var workout: Workout?
    @State private var saved = false

    var body: some View {
        WorkoutDetailView(workout: Binding(get: { workout ?? store.generate(focus: focus, minutes: minutes, seed: seed) },
                                           set: { workout = $0 }),
                          onRegenerate: {
                              seed += 1
                              workout = store.generate(focus: focus, minutes: minutes, seed: seed)
                          })
            .navigationTitle("Generated")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if workout == nil { workout = store.generate(focus: focus, minutes: minutes, seed: seed) } }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        seed += 1
                        withAnimation { workout = store.generate(focus: focus, minutes: minutes, seed: seed) }
                        store.haptic(.medium)
                    } label: { Image(systemName: "dice") }
                    Button {
                        if var w = workout {
                            w.id = UUID()
                            store.saveCustom(w)
                            saved = true
                        }
                    } label: { Image(systemName: "square.and.arrow.down") }
                }
            }
            .alert("Saved to My Workouts", isPresented: $saved) { Button("OK", role: .cancel) {} }
    }
}
