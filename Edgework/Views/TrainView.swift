import SwiftUI

struct TrainView: View {
    @EnvironmentObject var store: Store
    @State private var genFocus: Focus = .power
    @State private var genMinutes = 30
    @State private var building: Workout?
    @State private var showProfile = false

    private let minuteOptions = [15, 20, 30, 45, 60, 75]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SportMenu()
                    generator
                    if store.data.settings.sport == .track { trackTools } else { tools }
                    programs
                    mine
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .screenBackground()
            .navigationTitle("Train")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: { Image(systemName: "gearshape.fill") }
                }
            }
            .sheet(isPresented: $showProfile) { SettingsView().environmentObject(store) }
            .sheet(item: $building) { w in
                BuilderView(workout: w) { store.saveCustom($0) }
                    .environmentObject(store)
            }
        }
    }

    // MARK: Generator

    private var generator: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                IconBadge(symbol: "wand.and.stars", color: Theme.ice, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Workout generator").font(.headline).foregroundStyle(Theme.text)
                    Text("Pick a focus and time. Uses your gear and season phase.").font(.caption).foregroundStyle(Theme.text2)
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(Focus.generatable(for: store.data.settings.sport)) { f in
                    Button { genFocus = f; store.haptic(.light) } label: {
                        VStack(spacing: 6) {
                            Image(systemName: f.symbol).font(.system(size: 18, weight: .semibold)).frame(height: 22)
                            Text(f.shortTitle).font(.system(size: 12, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(genFocus == f ? Theme.bg : f.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(genFocus == f ? f.color : f.color.opacity(0.1)))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            Picker("Minutes", selection: $genMinutes) {
                ForEach(minuteOptions, id: \.self) { Text("\($0)m").tag($0) }
            }
            .pickerStyle(.segmented)
            NavigationLink {
                GeneratedScreen(focus: genFocus, minutes: genMinutes)
            } label: {
                Label("Generate \(genFocus.shortTitle.lowercased()) workout", systemImage: "sparkles")
            }
            .buttonStyle(PrimaryButtonStyle(color: genFocus.color))
        }
        .cardStyle()
    }

    // MARK: Tools

    private var trackTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Track tools")
            HStack(spacing: 10) {
                NavigationLink { StopwatchView() } label: {
                    toolTile("Stopwatch", "Laps and splits", "stopwatch.fill", Theme.ice)
                }
                NavigationLink { PaceCalculatorView() } label: {
                    toolTile("Pace Calculator", "Splits for any goal", "speedometer", Theme.amber)
                }
            }
            HStack(spacing: 10) {
                NavigationLink { TrackPRsView() } label: {
                    toolTile("PRs", "Times and marks", "trophy.fill", Theme.green)
                }
                NavigationLink { IntervalSetupView() } label: {
                    toolTile("Interval Timer", "Work / rest reps", "timer", Theme.red)
                }
            }
            HStack(spacing: 10) {
                NavigationLink { RunLogView() } label: {
                    toolTile("Running", "GPS runs & weekly distance", "figure.run", Color(hex: 0x22D3EE))
                }
                NavigationLink { MustDosEditor() } label: {
                    toolTile("Must-Dos", "Mandatory every time", "checklist", Theme.amber)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Tools")
            HStack(spacing: 10) {
                NavigationLink { IntervalSetupView() } label: {
                    toolTile("Shift Timer", "Work / rest intervals", "stopwatch.fill", Theme.red)
                }
                NavigationLink { BenchmarksView() } label: {
                    toolTile("Combine Tests", "Track your numbers", "chart.line.uptrend.xyaxis", Theme.green)
                }
            }
            if store.data.settings.showHockeyTools {
            HStack(spacing: 10) {
                NavigationLink { ShotTrackerView() } label: {
                    toolTile("Shot Tracker", "Count every puck", "scope", Color(hex: 0xB8F36B))
                }
                NavigationLink { StickhandlingView() } label: {
                    toolTile("Stickhandling", "Timer & daily minutes", "figure.hockey", Color(hex: 0xF5D76E))
                }
            }
            }
            HStack(spacing: 10) {
                NavigationLink { RunLogView() } label: {
                    toolTile("Running", "GPS runs & weekly distance", "figure.run", Color(hex: 0x22D3EE))
                }
                NavigationLink { MustDosEditor() } label: {
                    toolTile("Must-Dos", "Mandatory every time", "checklist", Theme.amber)
                }
            }
            if store.data.settings.showHockeyTools {
            HStack(spacing: 10) {
                NavigationLink { AimTrainerView() } label: {
                    toolTile("Aim Trainer", "Random target calls", "target", Color(hex: 0xB8F36B))
                }
                NavigationLink { HandsCallerView() } label: {
                    toolTile("Hands Caller", "React to called moves", "waveform", Color(hex: 0xF5D76E))
                }
            }
            NavigationLink { PuckCounterView() } label: {
                toolTile("Puck Counter", "Shoot the bucket, pick up every puck", "circle.grid.3x3.fill", Color(hex: 0xB8F36B))
            }
            }
        }
        .buttonStyle(PressableStyle())
    }

    private func toolTile(_ title: String, _ sub: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            IconBadge(symbol: symbol, color: color, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.text)
                Text(sub).font(.caption).foregroundStyle(Theme.text2)
            }
        }
        .cardStyle(padding: 14)
    }

    // MARK: Programs

    private var programs: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Programs", subtitle: "\(Programs.forSport(store.data.settings.sport).count) built-in sessions")
            VStack(spacing: 10) {
                ForEach(Programs.forSport(store.data.settings.sport)) { p in
                    NavigationLink { ProgramScreen(program: p) } label: { ProgramRow(program: p) }
                        .buttonStyle(PressableStyle())
                }
            }
        }
    }

    // MARK: Custom

    private var mine: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "My workouts", subtitle: store.data.custom.isEmpty ? nil : "\(store.data.custom.count) saved") {
                Button {
                    building = Workout(title: "", focus: .custom, items: [])
                } label: {
                    Label("New", systemImage: "plus").font(.subheadline.weight(.bold))
                }
            }
            if store.data.custom.isEmpty {
                EmptyState(symbol: "square.and.pencil", title: "Build your own",
                           message: "Make a workout from scratch, or save any program or generated workout with the save button.")
            } else {
                VStack(spacing: 10) {
                    ForEach(store.data.custom) { w in
                        NavigationLink { CustomWorkoutScreen(id: w.id) } label: {
                            HStack(spacing: 12) {
                                IconBadge(symbol: w.focus.symbol, color: w.focus.color, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(w.title.isEmpty ? "Untitled" : w.title).font(.headline).foregroundStyle(Theme.text)
                                    Text("\(store.estimateMinutes(w)) min · \(w.items.count) exercises").font(.footnote).foregroundStyle(Theme.text2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.text3)
                            }
                            .cardStyle(padding: 12)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }
}

struct ProgramRow: View {
    @EnvironmentObject var store: Store
    let program: Program

    var body: some View {
        let w = program.workout(rest: store.data.settings.rest)
        HStack(spacing: 14) {
            IconBadge(symbol: program.focus.symbol, color: program.focus.color, size: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(program.title).font(.display(20, .bold)).foregroundStyle(Theme.text)
                Text(program.subtitle).font(.footnote).foregroundStyle(Theme.text2).lineLimit(2).multilineTextAlignment(.leading)
                HStack(spacing: 10) {
                    Label("\(store.estimateMinutes(w)) min", systemImage: "clock")
                    Label("\(w.items.count)", systemImage: "list.bullet")
                    let missing = w.items.compactMap(\.exercise).flatMap(\.equipment).filter { !store.data.settings.equipment.contains($0) }
                    if !missing.isEmpty {
                        Label("Needs gear", systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.amber)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.text3)
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 14)
    }
}

// MARK: - Builder

struct BuilderView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var workout: Workout
    let onSave: (Workout) -> Void
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    TextField("Workout name", text: $workout.title)
                    TextField("Description (optional)", text: $workout.subtitle)
                    Picker("Focus", selection: $workout.focus) {
                        ForEach(Focus.allCases) { f in Label(f.title, systemImage: f.symbol).tag(f) }
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    ForEach($workout.items) { $item in
                        if let ex = item.exercise {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    IconBadge(symbol: ex.symbol, color: ex.category.color, size: 34)
                                    Text(ex.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                                    Spacer()
                                    Menu {
                                        Picker("Block", selection: $item.block) {
                                            ForEach(Block.allCases) { b in Text(b.title).tag(b) }
                                        }
                                    } label: {
                                        Chip(text: item.block.title, color: Theme.ice)
                                    }
                                }
                                HStack(spacing: 14) {
                                    Stepper(value: $item.sets, in: 1...12) {
                                        Text("\(item.sets) sets").font(.number(14)).foregroundStyle(Theme.text2)
                                    }
                                }
                                Stepper(value: $item.base, in: 1...900, step: ex.measure == .reps ? 1 : 5) {
                                    Text("\(ex.measure.format(item.base))\(ex.measure == .reps ? " reps" : "")\(ex.perSide ? " / side" : "")")
                                        .font(.number(14)).foregroundStyle(Theme.text2)
                                }
                                Stepper(value: $item.rest, in: 0...300, step: 5) {
                                    Text("Rest \(item.rest)s").font(.number(14)).foregroundStyle(Theme.text2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { workout.items.remove(atOffsets: $0) }
                    .onMove { workout.items.move(fromOffsets: $0, toOffset: $1) }
                    Button { showPicker = true } label: { Label("Add exercises", systemImage: "plus.circle.fill") }
                } header: {
                    Text("Exercises · ~\(store.estimateMinutes(workout)) min")
                } footer: {
                    Text("These are base values. Global intensity and your per-exercise tweaks still apply on top.")
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(workout.title.isEmpty ? "New workout" : workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if workout.title.trimmingCharacters(in: .whitespaces).isEmpty { workout.title = "My Workout" }
                        onSave(workout)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(workout.items.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) { EditButton() }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePicker { picked in
                    workout.items += picked.map { store.item(for: $0, block: $0.category == .warmup ? .warmup : .main) }
                }
                .environmentObject(store)
            }
        }
    }
}

// MARK: - Interval timer

struct IntervalSetupView: View {
    @EnvironmentObject var store: Store
    @AppStorage("interval.work") private var work = 40
    @AppStorage("interval.rest") private var rest = 80
    @AppStorage("interval.rounds") private var rounds = 8

    private struct Preset: Hashable {
        let name: String
        let work: Int
        let rest: Int
        let rounds: Int
    }

    private let presets = [
        Preset(name: "Game shift", work: 40, rest: 80, rounds: 8),
        Preset(name: "Tabata", work: 20, rest: 10, rounds: 8),
        Preset(name: "Long shift", work: 60, rest: 120, rounds: 6),
        Preset(name: "PP unit", work: 90, rest: 120, rounds: 4),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Shift Timer").font(.display(32)).foregroundStyle(Theme.text)
                    Text("Work hard for a shift, recover on the bench, repeat. Run, bike, jump rope or skater hops.")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { p in
                            Button {
                                work = p.work; rest = p.rest; rounds = p.rounds
                                store.haptic(.light)
                            } label: {
                                Chip(text: p.name, color: Theme.red, filled: work == p.work && rest == p.rest && rounds == p.rounds)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
                VStack(spacing: 0) {
                    row("Work", "\(work)s", Theme.red) { work = max(5, work - 5) } plus: { work = min(300, work + 5) }
                    Divider().overlay(Theme.stroke)
                    row("Rest", "\(rest)s", Theme.green) { rest = max(0, rest - 5) } plus: { rest = min(600, rest + 5) }
                    Divider().overlay(Theme.stroke)
                    row("Rounds", "\(rounds)", Theme.ice) { rounds = max(1, rounds - 1) } plus: { rounds = min(30, rounds + 1) }
                }
                .cardStyle(padding: 14)

                HStack {
                    StatTile(value: (rounds * work + max(0, rounds - 1) * rest).clock, label: "Total time", symbol: "clock.fill", color: Theme.ice)
                    StatTile(value: (rounds * work).clock, label: "Work time", symbol: "flame.fill", color: Theme.red)
                }

                Button {
                    store.start(Workout(title: "Shift Timer", subtitle: "\(rounds) × \(work)s / \(rest)s", focus: .conditioning,
                                        items: [WorkoutItem(exerciseID: "shift-sprints", sets: rounds, base: work, rest: rest, block: .main, fixed: true)]))
                } label: { Label("Start", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.red))
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String, _ color: Color, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack {
            Text(title).font(.headline).foregroundStyle(Theme.text)
            Spacer()
            TargetStepper(value: value, tint: color, minus: { minus(); store.haptic(.light) }, plus: { plus(); store.haptic(.light) })
        }
        .padding(.vertical, 10)
    }
}
