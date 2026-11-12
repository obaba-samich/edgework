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

    private var s: Binding<Settings> { $store.data.settings }

    var body: some View {
        NavigationStack {
            Form {
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
                            TextField("Your name", text: s.name).font(.headline)
                            Text("\(store.data.settings.position.title) · \(store.data.settings.phase.title)")
                                .font(.subheadline).foregroundStyle(Theme.text2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)

                Section {
                    Picker("Position", selection: s.position) {
                        ForEach(Position.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Season phase", selection: s.phase) {
                        ForEach(SeasonPhase.allCases) { Text($0.title).tag($0) }
                    }
                } header: { Text("Player") } footer: { Text(store.data.settings.phase.detail) }
                .listRowBackground(Theme.surface)

                Section {
                    Picker("Default length", selection: s.duration) {
                        ForEach([15, 20, 30, 45, 60, 75], id: \.self) { Text("\($0) min").tag($0) }
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
                    NavigationLink {
                        AdjustmentsView()
                    } label: {
                        HStack {
                            Text("Per-exercise adjustments")
                            Spacer()
                            Text("\(store.data.factors.count)").foregroundStyle(Theme.text2)
                        }
                    }
                } header: { Text("Training") } footer: {
                    Text("Changes apply to newly generated workouts. Tap the dice on Today to regenerate.")
                }
                .listRowBackground(Theme.surface)

                Section {
                    WeekdayPicker(title: "Game days", color: Theme.red, selection: s.gameDays)
                    WeekdayPicker(title: "Practice days", color: Theme.ice, selection: s.practiceDays)
                } header: { Text("Weekly schedule") } footer: {
                    Text("Game days get a short activation, the day after gets recovery, practice days stay light. One-off changes: tap a day on the Today screen.")
                }
                .listRowBackground(Theme.surface)

                Section {
                    ForEach(Equipment.allCases) { e in
                        Toggle(isOn: Binding(get: { store.data.settings.equipment.contains(e) },
                                             set: { on in
                                                 if on { store.data.settings.equipment.insert(e) } else { store.data.settings.equipment.remove(e) }
                                             })) {
                            Label {
                                Text(e.title)
                            } icon: {
                                Image(systemName: e.symbol).foregroundStyle(Theme.ice)
                            }
                        }
                    }
                } header: { Text("Equipment I have") } footer: {
                    Text("Bodyweight exercises are always available. The generator only picks what you can actually do.")
                }
                .listRowBackground(Theme.surface)

                Section("During workouts") {
                    Toggle("Haptics", isOn: s.haptics)
                    Toggle("Sounds", isOn: s.sounds)
                    Toggle("3-2-1 countdown", isOn: s.countdown)
                }
                .listRowBackground(Theme.surface)

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
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Profile")
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
            .confirmationDialog("Erase everything?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase all data", role: .destructive) { store.resetAll() }
            } message: {
                Text("History, benchmarks, custom workouts and settings will be deleted. This can't be undone.")
            }
            .onChange(of: store.data.settings.gameDays) { _, _ in store.data.today = nil; store.ensureToday() }
            .onChange(of: store.data.settings.practiceDays) { _, _ in store.data.today = nil; store.ensureToday() }
        }
    }

    private var initials: String {
        let parts = store.data.settings.name.split(separator: " ").prefix(2)
        return parts.compactMap(\.first).map(String.init).joined().uppercased()
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

            Button {
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
            }
        }
    }

    private var schedule: some View {
        pageScaffold("Schedule", "When do you play?", "Game days get a quick activation. The day after is a recovery flush.") {
            VStack(spacing: 18) {
                WeekdayPicker(title: "Game days", color: Theme.red, selection: $store.data.settings.gameDays)
                WeekdayPicker(title: "Practice days", color: Theme.ice, selection: $store.data.settings.practiceDays)
            }
            .foregroundStyle(Theme.text)
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
