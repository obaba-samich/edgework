import SwiftUI
import UniformTypeIdentifiers

struct BackupFile: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.data }
            .suggestedFileName("Edgework-Backup.json")
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var importing = false
    @State private var importResult: String?
    @State private var confirmReset = false
    @State private var regenerated = false
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss

    private var s: Binding<Settings> { $store.data.settings }
    private var st: Settings { store.data.settings }

    private var reminderTime: Binding<Date> {
        Binding(get: { Day.start(Date()).addingTimeInterval(TimeInterval(st.remindMinute * 60)) },
                set: { d in
                    let c = Day.cal.dateComponents([.hour, .minute], from: d)
                    store.data.settings.remindMinute = (c.hour ?? 17) * 60 + (c.minute ?? 0)
                })
    }

    var body: some View {
        NavigationStack {
            Form {
                profile
                player
                workout
                goals
                warmup
                lineWork
                running
                difficulty
                schedule
                notifications
                nutrition
                during
                data
                about
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Profile")
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                guard case .success(let url) = result else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                if let raw = try? Data(contentsOf: url), store.importBackup(raw) {
                    importResult = "Backup restored."
                } else {
                    importResult = "That file isn't an Edgework backup."
                }
            }
            .alert(importResult ?? "", isPresented: Binding(get: { importResult != nil }, set: { if !$0 { importResult = nil } })) {
                Button("OK", role: .cancel) {}
            }
            .alert("Today's workout rebuilt", isPresented: $regenerated) { Button("OK", role: .cancel) {} }
            .confirmationDialog("Erase everything?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase all data", role: .destructive) { store.resetAll() }
            } message: {
                Text("History, benchmarks, custom workouts and settings will be deleted. This can't be undone.")
            }
            .onChange(of: st.gameDays) { _, _ in rebuildIfAuto() }
            .onChange(of: st.practiceDays) { _, _ in rebuildIfAuto() }
            .onChange(of: st.remindDaily) { _, _ in refreshNotifications() }
            .onChange(of: st.remindGame) { _, _ in refreshNotifications() }
            .onChange(of: st.remindStreak) { _, _ in refreshNotifications() }
            .onChange(of: st.remindMinute) { _, _ in refreshNotifications() }
            .onChange(of: st.trainTimes) { _, _ in refreshNotifications() }
            .onChange(of: st.runRemind) { _, _ in refreshNotifications() }
            .onChange(of: st.runRemindDays) { _, _ in refreshNotifications() }
            .onChange(of: st.runMinute) { _, _ in refreshNotifications() }
            .onChange(of: st.remindWater) { _, _ in refreshNotifications() }
        }
    }

    private func rebuildIfAuto() {
        guard let t = store.data.today else { return }
        store.rebuildToday(seed: t.seed, focus: t.focus, duration: t.duration)
    }

    private func refreshNotifications() {
        Task {
            if st.remindDaily || st.remindGame || st.remindStreak || st.runRemind || st.remindWater { _ = await Notifier.requestPermission() }
            Notifier.reschedule(store)
        }
    }

    // MARK: Sections

    private var profile: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Theme.ice, Theme.iceDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    if initials.isEmpty {
                        Image(systemName: "figure.hockey").font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.bg)
                    } else {
                        Text(initials).font(.display(24)).foregroundStyle(Theme.bg)
                    }
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Your name", text: s.name).font(.headline).submitLabel(.done)
                    Text("\(st.position.title) · \(st.style.title) · \(st.phase.title)")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Theme.surface)
    }

    private var player: some View {
        Section {
            Picker("Training style", selection: s.style) {
                ForEach(TrainingStyle.allCases) { Text($0.title).tag($0) }
            }
            Picker("Position", selection: s.position) {
                ForEach(Position.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Season phase", selection: s.phase) {
                ForEach(SeasonPhase.allCases) { Text($0.title).tag($0) }
            }
        } header: { Text("Player") } footer: { Text("\(st.style.detail) \(st.phase.detail)") }
        .listRowBackground(Theme.surface)
    }

    private var workout: some View {
        Section {
            Picker("Default length", selection: s.duration) {
                ForEach([10, 15, 20, 30, 45, 60, 75, 90], id: \.self) { Text("\($0) min").tag($0) }
            }
            Picker("Rest periods", selection: s.rest) {
                ForEach(RestLength.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Global intensity")
                    Spacer()
                    Text("\(Int((store.intensity * 100).rounded()))%").font(.number(16)).foregroundStyle(Theme.ice)
                }
                Slider(value: s.intensity, in: 0.4...2.0, step: 0.05)
            }
            Toggle("Review before starting", isOn: s.reviewFirst)
            Button { rebuildIfAuto(); regenerated = true } label: {
                Label("Rebuild today's workout with these settings", systemImage: "arrow.triangle.2.circlepath")
            }
        } header: { Text("Workouts") } footer: {
            Text("Review before starting opens the full list when you tap Start, so you can swap, reorder or remove things first.")
        }
        .listRowBackground(Theme.surface)
    }

    private var warmup: some View {
        Section {
            Picker("Warm-up", selection: s.warmupMode) {
                ForEach(WarmupMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            if st.warmupMode == .routine {
                NavigationLink {
                    RoutineEditor()
                } label: {
                    HStack {
                        Text("My warm-up routine")
                        Spacer()
                        Text("\(st.warmupRoutine.count) moves").foregroundStyle(Theme.text2)
                    }
                }
            } else if st.warmupMode == .auto {
                Stepper("Dynamic moves: \(st.warmupCount)", value: s.warmupCount, in: 0...12)
                Stepper("Static stretches: \(st.stretchCount)", value: s.stretchCount, in: 0...10)
            }
            Stepper("Cool-down stretches: \(st.cooldownCount)", value: s.cooldownCount, in: 0...8)
        } header: { Text("Warm-up & stretching") } footer: {
            Text("Auto mixes walking moves (high knees, butt kickers, carioca…) with standing ones, then a block of still stretches. My routine runs your own list every time, like a team warm-up.")
        }
        .listRowBackground(Theme.surface)
    }

    private var lineWork: some View {
        Section {
            Toggle("Count travelling moves in lines", isOn: s.lineMode)
            Stepper("Lines per set: \(st.lineCount)", value: s.lineCount, in: 1...20)
            NavigationLink {
                LineMovesView()
            } label: {
                HStack {
                    Text("Per-exercise choices")
                    Spacer()
                    Text("\(st.measureModes.count) set").foregroundStyle(Theme.text2)
                }
            }
        } header: { Text("Line work") } footer: {
            Text("High knees, butt kicks, carioca, side lunges, skips and the rest get done line to line instead of by time or reps. Short lines? Bump up the count. −/+ on a move still scales it.")
        }
        .listRowBackground(Theme.surface)
    }

    private var running: some View {
        Section {
            Picker("Runs in workouts", selection: s.runMode) {
                ForEach(RunMode.allCases) { Text($0.title).tag($0) }
            }
            Toggle("Include Run Days in rotation", isOn: s.runDays)
        } header: { Text("Running") } footer: {
            Text("Jog adds a 3-minute warm-up jog. Run finisher ends with strides, 200s, hill sprints or shuttles. Run Days are full running sessions.")
        }
        .listRowBackground(Theme.surface)
    }

    private var difficulty: some View {
        Section {
            Picker("Hardest exercises", selection: s.maxLevel) {
                Text("Beginner only").tag(1)
                Text("Up to intermediate").tag(2)
                Text("Everything").tag(3)
            }
            Stepper("Extra sets: \(st.extraSets > 0 ? "+" : "")\(st.extraSets)", value: s.extraSets, in: -2...3)
            Toggle("Low impact (no jumping)", isOn: s.lowImpact)
            Toggle("Hockey drills (stickhandling, shooting)", isOn: s.includeHockey)
            NavigationLink {
                ExclusionsView()
            } label: {
                HStack {
                    Text("Never show these")
                    Spacer()
                    Text("\(st.excluded.count)").foregroundStyle(Theme.text2)
                }
            }
            NavigationLink {
                AdjustmentsView()
            } label: {
                HStack {
                    Text("Per-exercise adjustments")
                    Spacer()
                    Text("\(store.data.factors.count)").foregroundStyle(Theme.text2)
                }
            }
            NavigationLink {
                EquipmentView()
            } label: {
                HStack {
                    Text("Equipment I have")
                    Spacer()
                    Text("\(st.equipment.count)").foregroundStyle(Theme.text2)
                }
            }
        } header: { Text("Difficulty & exercises") }
        .listRowBackground(Theme.surface)
    }

    private var schedule: some View {
        Section {
            NavigationLink {
                CalendarView()
            } label: {
                HStack {
                    Label("Team calendar", systemImage: "calendar")
                    Spacer()
                    Text(store.data.events.isEmpty ? "Not set up" : "\(store.upcomingEvents.count) upcoming").foregroundStyle(Theme.text2)
                }
            }
            NavigationLink {
                WeeklyScheduleView()
            } label: {
                HStack {
                    Label("Repeating weekly days", systemImage: "repeat")
                    Spacer()
                    Text(st.gameDays.isEmpty && st.practiceDays.isEmpty ? "Off" : "\(st.gameDays.count + st.practiceDays.count) days").foregroundStyle(Theme.text2)
                }
            }
        } header: { Text("Schedule") } footer: {
            Text("Import your Crossbar calendar so game days get an activation and the next day a recovery session. Or tap any day on Today to mark it by hand.")
        }
        .listRowBackground(Theme.surface)
    }

    private var runTime: Binding<Date> {
        Binding(get: { Day.start(Date()).addingTimeInterval(TimeInterval(st.runMinute * 60)) },
                set: { d in
                    let c = Day.cal.dateComponents([.hour, .minute], from: d)
                    store.data.settings.runMinute = (c.hour ?? 7) * 60 + (c.minute ?? 0)
                })
    }

    private var notifications: some View {
        Section {
            NavigationLink {
                TrainingTimesView()
            } label: {
                HStack {
                    Label("Workout times", systemImage: "clock.fill")
                    Spacer()
                    Text(st.trainTimes.isEmpty ? "Not set" : "\(st.trainTimes.count) days").foregroundStyle(Theme.text2)
                }
            }
            Toggle("Workout reminders", isOn: s.remindDaily)
            if st.remindDaily && st.trainTimes.isEmpty {
                DatePicker("Every day at", selection: reminderTime, displayedComponents: .hourAndMinute)
            }
            Toggle("Run reminders", isOn: s.runRemind)
            if st.runRemind {
                WeekdayPicker(title: "Run days", color: Color(hex: 0x22D3EE), selection: s.runRemindDays)
                DatePicker("Run time", selection: runTime, displayedComponents: .hourAndMinute)
            }
            Toggle("Water reminders (every 2 h)", isOn: s.remindWater)
            Toggle("Game-day activation reminder", isOn: s.remindGame)
            Toggle("Streak saver (8 PM)", isOn: s.remindStreak)
        } header: { Text("Schedule & reminders") } footer: {
            Text("Set a time for each day you train and you'll get a reminder with that day's workout. Shot-goal reminders come at 7 PM if you're short.")
        }
        .listRowBackground(Theme.surface)
    }

    private var goals: some View {
        Section {
            Stepper("Shots per day: \(st.shotGoal)", value: s.shotGoal, in: 0...1000, step: 25)
            Stepper("Stickhandling: \(st.stickGoal) min/day", value: s.stickGoal, in: 0...120, step: 5)
            Stepper("Water: \(st.waterGoal) glasses/day", value: s.waterGoal, in: 0...20)
            Stepper("Running: \(store.distanceText(st.runGoalKm))/week", value: s.runGoalKm, in: 0...150, step: 1)
            NavigationLink {
                MustDosEditor()
            } label: {
                HStack {
                    Label("Must-dos in every workout", systemImage: "checklist")
                    Spacer()
                    Text(st.mustDos.isEmpty ? "None" : "\(st.mustDos.count)").foregroundStyle(Theme.text2)
                }
            }
        } header: { Text("Goals & must-dos") } footer: {
            Text("Must-dos are mandatory items, like a required run or 100 shots, added to every generated workout.")
        }
        .listRowBackground(Theme.surface)
    }

    private var nutrition: some View {
        Section {
            NavigationLink {
                NutritionSettingsView()
            } label: {
                HStack {
                    Label("Nutrition profile", systemImage: "fork.knife")
                    Spacer()
                    Text("\(Int(store.targets.kcal)) kcal · \(Int(store.targets.protein))g P").foregroundStyle(Theme.text2)
                }
            }
            Picker("Units", selection: s.units) {
                ForEach(Units.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        } header: { Text("Nutrition") }
        .listRowBackground(Theme.surface)
    }

    private var during: some View {
        Section("During workouts") {
            Toggle("Haptics", isOn: s.haptics)
            Toggle("Sounds", isOn: s.sounds)
            Toggle("3-2-1 countdown", isOn: s.countdown)
            Toggle("Auto-start after rest", isOn: s.autoAdvance)
        }
        .listRowBackground(Theme.surface)
    }

    private var data: some View {
        Section {
            ShareLink(item: BackupFile(data: (try? JSONEncoder.edgework.encode(store.data)) ?? Data()),
                      preview: SharePreview("Edgework backup")) {
                Label("Export backup", systemImage: "square.and.arrow.up")
            }
            Button { importing = true } label: { Label("Import backup", systemImage: "square.and.arrow.down") }
            Button(role: .destructive) { confirmReset = true } label: { Label("Reset all data", systemImage: "trash") }
        } header: { Text("Data") } footer: {
            Text("Sideloaded apps can lose data if they're deleted. Export a backup to Files now and then.")
        }
        .listRowBackground(Theme.surface)
    }

    private var about: some View {
        Section {
            HStack {
                Text("Edgework")
                Spacer()
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") · \(Library.all.count) exercises")
                    .foregroundStyle(Theme.text2)
            }
        } footer: {
            Text("Not medical advice. Stop if something hurts, and warm up before explosive work.")
        }
        .listRowBackground(Theme.surface)
    }

    private var initials: String {
        let parts = st.name.split(separator: " ").prefix(2)
        return parts.compactMap(\.first).map(String.init).joined().uppercased()
    }
}

// MARK: - Sub-screens

struct EquipmentView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        Form {
            Section {
                ForEach(Equipment.allCases) { e in
                    Toggle(isOn: Binding(get: { store.data.settings.equipment.contains(e) },
                                         set: { on in
                                             if on { store.data.settings.equipment.insert(e) } else { store.data.settings.equipment.remove(e) }
                                         })) {
                        Label { Text(e.title) } icon: { Image(systemName: e.symbol).foregroundStyle(Theme.ice) }
                    }
                }
            } footer: { Text("Bodyweight exercises are always available.") }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklyScheduleView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        Form {
            Section {
                WeekdayPicker(title: "Game days", color: Theme.red, selection: $store.data.settings.gameDays)
                WeekdayPicker(title: "Practice days", color: Theme.ice, selection: $store.data.settings.practiceDays)
            } footer: {
                Text("Only use this if the same days repeat every week. The calendar import and one-off day marks override it.")
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Weekly days")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExclusionsView: View {
    @EnvironmentObject var store: Store
    @State private var picking = false

    var body: some View {
        let ids = store.data.settings.excluded.sorted { (Library.byID[$0]?.name ?? $0) < (Library.byID[$1]?.name ?? $1) }
        List {
            Section {
                if ids.isEmpty {
                    Text("Nothing excluded. Add exercises you can't or don't want to do and the generator will skip them.")
                        .foregroundStyle(Theme.text2)
                }
                ForEach(ids, id: \.self) { id in
                    if let ex = Library.byID[id] {
                        ExerciseRowLabel(exercise: ex)
                    }
                }
                .onDelete { idx in
                    for i in idx { store.data.settings.excluded.remove(ids[i]) }
                }
                Button { picking = true } label: { Label("Add exercises", systemImage: "plus.circle.fill") }
            } footer: { Text("Swipe to remove. You can also exclude from any exercise's page.") }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Never show")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $picking) {
            ExercisePicker { picked in
                for ex in picked { store.data.settings.excluded.insert(ex.id) }
            }
            .environmentObject(store)
        }
    }
}

struct RoutineEditor: View {
    @EnvironmentObject var store: Store
    @State private var picking = false

    static let teamTemplate: [(String, Block)] = [
        ("warmup-jog", .warmup), ("high-knees", .warmup), ("butt-kickers", .warmup), ("knee-hugs", .warmup),
        ("walking-quad-pull", .warmup), ("frankenstein", .warmup), ("walking-lunge-twist", .warmup), ("carioca", .warmup),
        ("a-skips", .warmup), ("lateral-shuffle-warm", .warmup), ("leg-swings-front", .warmup), ("leg-swings-lateral", .warmup),
        ("quad-stretch", .stretch), ("standing-hamstring", .stretch), ("standing-groin", .stretch), ("butterfly-stretch", .stretch),
        ("cross-body-shoulder", .stretch), ("tricep-stretch", .stretch), ("calf-stretch", .stretch),
    ]

    private var routine: Binding<[WorkoutItem]> { $store.data.settings.warmupRoutine }

    var body: some View {
        List {
            Section {
                Button {
                    store.data.settings.warmupRoutine = Self.teamTemplate.compactMap { pair -> WorkoutItem? in
                        guard let ex = Library.byID[pair.0] else { return nil }
                        return store.item(for: ex, block: pair.1)
                    }
                } label: { Label("Load team-style template", systemImage: "person.3.fill") }
                Button { picking = true } label: { Label("Add exercises", systemImage: "plus.circle.fill") }
            } footer: {
                Text("Walking dynamic moves first, then still stretches. Runs at the start of every generated workout.")
            }
            .listRowBackground(Theme.surface)

            Section {
                ForEach(routine) { $item in
                    if let ex = item.exercise {
                        HStack(spacing: 10) {
                            IconBadge(symbol: ex.symbol, color: item.block == .stretch ? Theme.green : ex.category.color, size: 34)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ex.name).font(.subheadline.weight(.semibold))
                                Menu {
                                    Picker("Block", selection: $item.block) {
                                        Text(Block.warmup.title).tag(Block.warmup)
                                        Text(Block.stretch.title).tag(Block.stretch)
                                    }
                                } label: {
                                    Text(item.block.title).font(.caption.weight(.bold)).foregroundStyle(Theme.ice)
                                }
                            }
                            Spacer()
                            Stepper(value: $item.base, in: 1...900, step: ex.measure == .reps ? 1 : 5) {
                                Text("\(ex.measure.format(item.base))\(ex.measure == .reps ? " reps" : "")")
                                    .font(.number(14)).foregroundStyle(Theme.text2)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .fixedSize()
                        }
                    }
                }
                .onDelete { routine.wrappedValue.remove(atOffsets: $0) }
                .onMove { routine.wrappedValue.move(fromOffsets: $0, toOffset: $1) }
            } header: {
                Text(store.data.settings.warmupRoutine.isEmpty ? "No moves yet" : "\(store.data.settings.warmupRoutine.count) moves · ~\(max(1, store.data.settings.warmupRoutine.map(store.estimateSeconds).reduce(0, +) / 60)) min")
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Warm-up routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $picking) {
            ExercisePicker { picked in
                routine.wrappedValue += picked.map { store.item(for: $0, block: Library.staticStretchIDs.contains($0.id) ? .stretch : .warmup) }
            }
            .environmentObject(store)
        }
    }
}

struct CalendarView: View {
    @EnvironmentObject var store: Store
    @State private var importing = false
    @State private var message: String?
    @State private var syncing = false

    private var icsTypes: [UTType] {
        var t: [UTType] = [.calendarEvent]
        if let ics = UTType(filenameExtension: "ics") { t.append(ics) }
        t.append(.data)
        return t
    }

    var body: some View {
        List {
            Section {
                Button { importing = true } label: { Label("Import .ics file", systemImage: "doc.badge.plus") }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subscription link").font(.subheadline.weight(.semibold))
                    TextField("webcal:// or https:// link", text: $store.data.settings.calendarURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.done)
                        .font(.footnote)
                }
                Button {
                    syncing = true
                    Task {
                        message = await store.syncCalendar()
                        syncing = false
                    }
                } label: {
                    HStack {
                        Label("Sync now", systemImage: "arrow.clockwise")
                        if syncing { Spacer(); ProgressView() }
                    }
                }
                .disabled(store.data.settings.calendarURL.isEmpty || syncing)
                if let last = store.data.lastSync {
                    Text("Last updated \(last.formatted(.relative(presentation: .named)))").font(.caption).foregroundStyle(Theme.text3)
                }
            } header: { Text("Source") } footer: {
                Text("In Crossbar, export or share your schedule as a calendar (.ics) file and open it with Edgework, or copy its calendar subscription link here. Linked calendars refresh every time you open the app.")
            }
            .listRowBackground(Theme.surface)

            Section {
                let upcoming = store.data.events.filter { $0.start >= Day.start(Date()) }.prefix(60)
                if upcoming.isEmpty {
                    Text("No upcoming events.").foregroundStyle(Theme.text2)
                }
                ForEach(Array(upcoming)) { e in
                    HStack(spacing: 12) {
                        let k = store.kind(e)
                        Image(systemName: k == .game ? "flag.checkered" : (k == .practice ? "figure.ice.skating" : "minus.circle"))
                            .foregroundStyle(k == .game ? Theme.red : (k == .practice ? Theme.ice : Theme.text3))
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.title).font(.subheadline.weight(.semibold)).foregroundStyle(k == .ignore ? Theme.text3 : Theme.text)
                            Text(e.allDay ? e.start.formatted(.dateTime.weekday().month().day()) : e.start.formatted(.dateTime.weekday().month().day().hour().minute()))
                                .font(.caption).foregroundStyle(Theme.text2)
                        }
                        Spacer()
                        Menu {
                            ForEach(EventKind.allCases) { kind in
                                Button { store.setKind(kind, for: e) } label: {
                                    if kind == k { Label(kind.title, systemImage: "checkmark") } else { Text(kind.title) }
                                }
                            }
                        } label: {
                            Chip(text: k.title, color: k == .game ? Theme.red : (k == .practice ? Theme.ice : Theme.text3))
                        }
                    }
                }
            } header: { Text("Upcoming") } footer: {
                Text("Edgework guesses games and practices from event names. Tap the tag to correct one.")
            }
            .listRowBackground(Theme.surface)

            if !store.data.events.isEmpty {
                Section {
                    Button("Remove calendar", role: .destructive) {
                        store.data.events = []
                        store.data.eventKinds = [:]
                        store.data.settings.calendarURL = ""
                        store.data.lastSync = nil
                    }
                }
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Team calendar")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $importing, allowedContentTypes: icsTypes) { result in
            if case .success(let url) = result { message = store.importCalendar(from: url) }
        }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        }
    }
}

struct LineMovesView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let moves = Library.all.filter { Library.travelIDs.contains($0.id) }
        List {
            Section {
                ForEach(moves) { ex in
                    HStack {
                        Text(ex.name).font(.subheadline)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { store.data.settings.measureModes[ex.id] ?? "global" },
                            set: { v in store.data.settings.measureModes[ex.id] = v == "global" ? nil : v })) {
                            Text("Global").tag("global")
                            Text("Lines").tag("lines")
                            Text(ex.measure == .seconds ? "Time" : "Reps").tag("default")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }
            } footer: { Text("Global follows the Line work switch. Pick Lines or Time/Reps to lock one exercise either way.") }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Line moves")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TrainingTimesView: View {
    @EnvironmentObject var store: Store

    private func binding(_ wd: Int) -> Binding<Date> {
        Binding(get: { Day.start(Date()).addingTimeInterval(TimeInterval((store.data.settings.trainTimes[String(wd)] ?? 17 * 60) * 60)) },
                set: { d in
                    let c = Day.cal.dateComponents([.hour, .minute], from: d)
                    store.data.settings.trainTimes[String(wd)] = (c.hour ?? 17) * 60 + (c.minute ?? 0)
                })
    }

    var body: some View {
        Form {
            Section {
                ForEach(Day.mondayFirst, id: \.self) { wd in
                    let on = store.data.settings.trainTimes[String(wd)] != nil
                    HStack {
                        Toggle(isOn: Binding(get: { on }, set: { v in store.data.settings.trainTimes[String(wd)] = v ? 17 * 60 : nil })) {
                            Text(Calendar.current.weekdaySymbols[wd - 1])
                        }
                        .fixedSize()
                        Spacer()
                        if on {
                            DatePicker("", selection: binding(wd), displayedComponents: .hourAndMinute).labelsHidden()
                        } else {
                            Text("Rest").foregroundStyle(Theme.text3)
                        }
                    }
                }
            } footer: {
                Text("Turn on Workout reminders in Profile to get notified at these times. Today shows your planned time.")
            }
            .listRowBackground(Theme.surface)
            Section {
                Button("Same time every day (5:00 PM)") {
                    for wd in 1...7 { store.data.settings.trainTimes[String(wd)] = 17 * 60 }
                }
                Button("Clear all", role: .destructive) { store.data.settings.trainTimes = [:] }
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Workout times")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MustDosEditor: View {
    @EnvironmentObject var store: Store
    @State private var picking = false

    private var items: Binding<[WorkoutItem]> { $store.data.settings.mustDos }

    var body: some View {
        List {
            Section {
                ForEach(Store.mustDoPresets.indices, id: \.self) { i in
                    Button { store.addMustDoPreset(i) } label: {
                        Label(Store.mustDoPresets[i].title, systemImage: "plus.circle")
                    }
                }
                Button { picking = true } label: { Label("Pick any exercise", systemImage: "list.bullet") }
            } header: { Text("Add") } footer: {
                Text("Runs, shots, stickhandling, push-ups: anything you have to do every time.")
            }
            .listRowBackground(Theme.surface)

            Section {
                if store.data.settings.mustDos.isEmpty {
                    Text("No must-dos yet.").foregroundStyle(Theme.text2)
                }
                ForEach(items) { $item in
                    if let ex = item.exercise {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                IconBadge(symbol: ex.symbol, color: ex.category.color, size: 32)
                                Text(ex.name).font(.subheadline.weight(.semibold))
                            }
                            Stepper("\(item.sets) sets", value: $item.sets, in: 1...20).font(.footnote)
                            Stepper("\(ex.measure.format(item.base))\(ex.measure == .reps ? " reps" : "")", value: $item.base, in: 1...20000,
                                    step: ex.measure == .reps ? 5 : (ex.measure == .meters ? 100 : 30))
                                .font(.footnote)
                        }
                    }
                }
                .onDelete { items.wrappedValue.remove(atOffsets: $0) }
                .onMove { items.wrappedValue.move(fromOffsets: $0, toOffset: $1) }
            } header: { Text("Your must-dos") }
            .listRowBackground(Theme.surface)

            Section {
                Toggle("Also add to programs", isOn: $store.data.settings.mustDosInPrograms)
            } footer: { Text("Must-dos always go into generated workouts. Turn this on to add them to built-in programs too.") }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Must-dos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $picking) {
            ExercisePicker { picked in
                for ex in picked {
                    var it = store.item(for: ex, block: .main)
                    it.block = .musts
                    items.wrappedValue.append(it)
                }
            }
            .environmentObject(store)
        }
    }
}

struct NutritionSettingsView: View {
    @EnvironmentObject var store: Store
    private var s: Binding<Settings> { $store.data.settings }
    private var st: Settings { store.data.settings }

    var body: some View {
        let t = store.targets
        let imperial = st.units == .imperial
        Form {
            Section {
                HStack(spacing: 10) {
                    target("\(Int(t.kcal))", "kcal", Theme.amber)
                    target("\(Int(t.protein))g", "protein", Theme.green)
                    target("\(Int(t.carbs))g", "carbs", Theme.amber)
                    target("\(Int(t.fat))g", "fat", Theme.ice)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            Section {
                Picker("Goal", selection: s.nutritionGoal) {
                    ForEach(NutritionGoal.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Sex", selection: s.sex) {
                    ForEach(Sex.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Stepper("Age: \(st.age)", value: s.age, in: 10...80)
                Stepper(imperial ? "Weight: \(Int((st.weightKg * 2.20462).rounded())) lb" : "Weight: \(Int(st.weightKg.rounded())) kg",
                        value: Binding(get: { imperial ? st.weightKg * 2.20462 : st.weightKg },
                                       set: { store.data.settings.weightKg = imperial ? $0 / 2.20462 : $0 }),
                        in: 50...400, step: 1)
                Stepper(imperial ? "Height: \(Int(st.heightCm / 2.54) / 12)' \(Int(st.heightCm / 2.54) % 12)\"" : "Height: \(Int(st.heightCm)) cm",
                        value: Binding(get: { imperial ? st.heightCm / 2.54 : st.heightCm },
                                       set: { store.data.settings.heightCm = imperial ? $0 * 2.54 : $0 }),
                        in: 40...230, step: 1)
            } header: { Text("About you") } footer: {
                Text("Targets use the Mifflin-St Jeor formula with an active-athlete multiplier, about 1.8 g/kg protein, and 28% of calories from fat.")
            }
            .listRowBackground(Theme.surface)
            Section {
                Stepper(st.kcalOverride == 0 ? "Calories: auto" : "Calories: \(st.kcalOverride)", value: s.kcalOverride, in: 0...6000, step: 50)
                Stepper(st.proteinOverride == 0 ? "Protein: auto" : "Protein: \(st.proteinOverride) g", value: s.proteinOverride, in: 0...400, step: 5)
            } header: { Text("Manual targets") } footer: { Text("Set to 0 for automatic.") }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func target(_ v: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.number(18)).foregroundStyle(Theme.text)
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
    }
}

struct WeekdayPicker: View {
    let title: String
    let color: Color
    @Binding var selection: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            HStack(spacing: 6) {
                ForEach(Day.mondayFirst, id: \.self) { wd in
                    let on = selection.contains(wd)
                    Button {
                        if on { selection.remove(wd) } else { selection.insert(wd) }
                    } label: {
                        Text(String(Day.shortNames[wd]?.prefix(2) ?? ""))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(on ? Theme.bg : Theme.text2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(on ? color : Theme.surface2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdjustmentsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let ids = store.data.factors.keys.sorted { (Library.byID[$0]?.name ?? $0) < (Library.byID[$1]?.name ?? $1) }
        List {
            if ids.isEmpty {
                Section {
                    Text("No tweaks yet. Tap − or + on any exercise in a workout and it'll be remembered here.")
                        .foregroundStyle(Theme.text2)
                }
                .listRowBackground(Theme.surface)
            } else {
                Section {
                    ForEach(ids, id: \.self) { id in
                        if let ex = Library.byID[id] {
                            let item = store.item(for: ex, block: .main)
                            HStack(spacing: 12) {
                                IconBadge(symbol: ex.symbol, color: ex.category.color, size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name).font(.subheadline.weight(.semibold))
                                    Text("\(Int((store.factor(id) * 100).rounded()))% of default")
                                        .font(.caption).foregroundStyle(Theme.text2)
                                }
                                Spacer()
                                TargetStepper(value: store.targetText(item),
                                              minus: { store.adjust(item, up: false) },
                                              plus: { store.adjust(item, up: true) })
                            }
                            .swipeActions {
                                Button("Reset") { store.resetFactor(id) }.tint(Theme.ice)
                            }
                        }
                    }
                } footer: { Text("Swipe left to reset one.") }
                .listRowBackground(Theme.surface)

                Section {
                    Button("Reset all exercises to default", role: .destructive) { store.data.factors = [:] }
                }
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Adjustments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject var store: Store
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                player.tag(1)
                schedule.tag(2)
                gear.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onChange(of: page) { _, _ in hideKeyboard() }

            Button {
                hideKeyboard()
                if page < 3 {
                    withAnimation { page += 1 }
                } else {
                    store.data.today = nil
                    store.ensureToday()
                    store.data.onboarded = true
                }
            } label: {
                Text(page < 3 ? "Continue" : "Start training")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(20)
        }
        .screenBackground()
    }

    private func pageScaffold<Content: View>(_ overline: String, _ title: String, _ text: String, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Overline(overline, color: Theme.ice)
                Text(title).font(.display(38)).foregroundStyle(Theme.text)
                Text(text).font(.body).foregroundStyle(Theme.text2)
                content().padding(.top, 8)
            }
            .padding(24)
            .padding(.top, 30)
        }
    }

    private var welcome: some View {
        pageScaffold("Edgework", "Off-ice training built for hockey.", "A fresh workout every day that knows when you have games, what gear you own and how hard you want to push.") {
            VStack(alignment: .leading, spacing: 14) {
                feature("wand.and.stars", "Daily generator", "Strength, power, speed, hands. Rotates automatically.")
                feature("plusminus", "Tune anything", "One tap scales every rep, or adjust a single exercise.")
                feature("figure.hockey", "\(Library.all.count) hockey drills", "With steps, cues and the muscles they hit.")
                feature("chart.bar.xaxis", "Progress", "Streaks, muscle maps and combine-style tests.")
            }
        }
    }

    private var player: some View {
        pageScaffold("About you", "Who's lacing up?", "This shapes what the generator picks.") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Your name", text: $store.data.settings.name)
                    .submitLabel(.done)
                    .onSubmit { hideKeyboard() }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
                Overline("Position")
                Picker("Position", selection: $store.data.settings.position) {
                    ForEach(Position.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Overline("Season")
                Picker("Season", selection: $store.data.settings.phase) {
                    ForEach(SeasonPhase.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(store.data.settings.phase.detail).font(.footnote).foregroundStyle(Theme.text3)
                Overline("Workouts")
                Picker("Style", selection: $store.data.settings.style) {
                    ForEach(TrainingStyle.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(store.data.settings.style.detail).font(.footnote).foregroundStyle(Theme.text3)
            }
        }
    }

    private var schedule: some View {
        pageScaffold("Schedule", "Games all over the place?", "No fixed schedule needed. Edgework picks whatever you've trained least recently, and adapts around games.") {
            VStack(alignment: .leading, spacing: 14) {
                feature("calendar.badge.plus", "Import your team calendar", "Profile → Team calendar. Open a Crossbar .ics export or paste its subscription link.")
                feature("hand.tap.fill", "Or mark days by hand", "Tap any day on the Today screen to set Game, Practice or Training.")
                feature("flag.checkered", "Game day", "Short activation to feel fast, not tired.")
                feature("leaf.fill", "Day after", "Recovery flush and stretching.")
            }
        }
    }

    private var gear: some View {
        pageScaffold("Equipment", "What do you have?", "You can change this anytime in Profile.") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Equipment.allCases) { e in
                    let on = store.data.settings.equipment.contains(e)
                    Button {
                        if on { store.data.settings.equipment.remove(e) } else { store.data.settings.equipment.insert(e) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: e.symbol).frame(width: 20)
                            Text(e.title).font(.system(size: 14, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(on ? Theme.bg : Theme.text)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(on ? Theme.ice : Theme.surface))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private func feature(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            IconBadge(symbol: symbol, color: Theme.ice, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.text)
                Text(text).font(.subheadline).foregroundStyle(Theme.text2)
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
