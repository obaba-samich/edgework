import SwiftUI

@main
struct EdgeworkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = Store()

    init() {
        Appearance.apply()
        // A fresh launch has no workout or run going, so any Live Activity still showing is left over from a closed app.
        Task { @MainActor in LiveActivity.end() }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Theme.ice)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Swiping the app away mid-workout or mid-run would otherwise leave the Dynamic Island up.
    func applicationWillTerminate(_ application: UIApplication) {
        LiveActivity.endAllBeforeExit()
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    static let tabTitles = ["Today", "Train", "Library", "Fuel", "Progress"]
    static let tabSymbols = ["figure.hockey", "square.stack.3d.up.fill", "books.vertical.fill", "fork.knife", "chart.bar.xaxis"]

    private var visibleTabs: [Int] { store.data.settings.showFuel ? [0, 1, 2, 3, 4] : [0, 1, 2, 4] }

    @ViewBuilder
    private func tabContent(_ t: Int) -> some View {
        switch t {
        case 0: TodayView()
        case 1: TrainView()
        case 2: LibraryView()
        case 3: FuelView()
        default: StatsView()
        }
    }
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = DebugHooks.integer("startTab")
    @State private var debugSheet = DebugHooks.string("showScreen")
    @State private var calendarMessage: String?
    @State private var showRun = false
    @ObservedObject private var siri = SiriRouter.shared
    @State private var siriScreen: AppSection?

    var body: some View {
        // Tabs come from a stable list (not an `if` inside the TabView), which kept eating the first tap on Library and Fuel.
        TabView(selection: $tab) {
            ForEach(visibleTabs, id: \.self) { t in
                tabContent(t)
                    .tabItem { Label(Self.tabTitles[t], systemImage: t == 0 ? store.data.settings.sport.symbol : Self.tabSymbols[t]) }
                    .tag(t)
            }
        }
        .id(store.data.settings.sport)
        .tint(Theme.ice)
        .fullScreenCover(item: $store.activeWorkout) { workout in
            PlayerView(workout: workout, store: store)
                .environmentObject(store)
        }
        .sheet(isPresented: Binding(get: { !store.data.onboarded }, set: { if !$0 { store.data.onboarded = true } })) {
            OnboardingView()
                .environmentObject(store)
                .interactiveDismissDisabled()
        }
        .sheet(item: Binding(get: { debugSheet.map(DebugScreen.init) }, set: { debugSheet = $0?.id })) { screen in
            NavigationStack {
                if let ex = Library.byID[screen.id] {
                    ExerciseDetailView(exercise: ex)
                } else if screen.id == "calendar" {
                    CalendarView()
                } else if screen.id == "keywords" {
                    KeywordsView()
                } else if screen.id == "aimcustom" {
                    AimTrainerView().onAppear {
                        UserDefaults.standard.set(false, forKey: "aimRandomize")
                        UserDefaults.standard.set(true, forKey: "aimUseCustom")
                        UserDefaults.standard.set("wrist:topLeft,snap:lowRight,backhand:fiveHole", forKey: "aimCustomShots")
                    }
                } else if screen.id == "shareworkout", let p = Programs.all.first(where: { $0.id == "wrists" }) {
                    WorkoutShareSheet(workout: store.programWorkout(p))
                } else if screen.id == "sharecard" {
                    ShareCardSheet(title: "Week", card: store.weekCard)
                } else if screen.id == "aimheat" {
                    AimTrainerView().onAppear {
                        let demo: [(String, Int, Int)] = [("wrist:topLeft", 9, 3), ("wrist:topRight", 5, 7), ("snap:lowLeft", 8, 2),
                                                          ("snap:lowRight", 6, 4), ("wrist:fiveHole", 7, 1), ("backhand:topMiddle", 2, 6)]
                        for (k, h, m) in demo { store.data.aimZones[k] = AimZoneStat(called: h + m, hits: h, misses: m) }
                    }
                } else if screen.id == "study" {
                    StudyView().onAppear { store.data.settings.knowledgeLevel = 3; store.data.settings.learned = ["a-skips", "goblet-squat"] }
                } else if screen.id == "routine" {
                    RoutineEditor()
                } else if screen.id == "log" {
                    ManualLogView()
                } else if screen.id == "settings" {
                    SettingsView()
                } else if screen.id == "mealgen" {
                    MealGeneratorView(meal: .postWorkout, date: Date())
                } else if screen.id == "scan" {
                    FoodScanView(mode: .label) { _ in }
                } else if screen.id == "prs" {
                    TrackPRsView()
                } else if screen.id == "pace" {
                    PaceCalculatorView()
                } else if screen.id == "pucks" {
                    PuckCounterView()
                } else if screen.id == "aim" {
                    AimTrainerView()
                } else if screen.id == "shots" {
                    ShotTrackerView()
                } else if screen.id == "addfood" {
                    AddFoodView(meal: .breakfast, date: Date())
                } else if screen.id == "howto" {
                    HowToSheet(exercise: Library.byID["walking-lunge-twist"]!)
                } else if screen.id == "reminders" {
                    SettingsView(debugPage: "reminders")
                } else if screen.id == "diet" {
                    DietNotesView()
                } else if screen.id == "drink" {
                    FoodDetailSheet(food: FoodDB.byID["sports-drink"]!, meal: .drinks, date: Date(), existing: nil)
                } else if screen.id == "editfood" {
                    FoodEditor(food: FoodDB.byID["donut"] ?? FoodDB.all[0]) { _ in }
                } else if screen.id == "gps" {
                    GPSRunView()
                } else if screen.id == "trackmeet" {
                    SettingsView(debugPage: "track")
                } else if screen.id == "hockeysettings" {
                    SettingsView(debugPage: "hockey")
                } else if screen.id == "food" {
                    FoodDetailSheet(food: FoodDB.byID["pbj"]!, meal: .preGame, date: Date(), existing: nil)
                } else {
                    TodayWorkoutScreen()
                }
            }
            .environmentObject(store)
        }
        .onAppear {
            if DebugHooks.bool("autoStart"), let w = store.data.today?.workout { store.start(w) }
            if let id = DebugHooks.string("autoStartExercise"), let ex = Library.byID[id] {
                store.data.hillClimbs[id] = [41.2, 43.0, 44.1]
                store.start(Workout(title: ex.name, subtitle: "", focus: .custom, items: [store.item(for: ex, block: .main)]))
            }
        }
        .sheet(item: $siriScreen) { section in
            Group {
                // Settings and Fuel bring their own navigation stacks; the rest need one.
                if section == .settings {
                    SettingsView()
                } else if section == .food {
                    FuelView()
                } else {
                    NavigationStack {
                        switch section {
                        case .shooting: ShotTrackerView()
                        case .stickhandling: StickhandlingView()
                        case .running: RunLogView()
                        default: StudyView()
                        }
                    }
                }
            }
            .environmentObject(store)
        }
        .onChange(of: siri.pending) { _, action in handleSiri() }
        .onAppear { handleSiri() }
        .sheet(isPresented: $showRun) {
            NavigationStack { GPSRunView() }.environmentObject(store)
        }
        .sheet(item: $store.pendingImport) { w in
            WorkoutImportSheet(workout: w).environmentObject(store)
        }
        .onOpenURL { url in
            if url.scheme == "edgework" {
                if let result = WorkoutLink.workout(from: url.absoluteString) {
                    store.pendingImport = result.workout
                    if result.dropped > 0 { calendarMessage = "\(result.dropped) exercises in that workout aren't in this version of Edgework, so they were left out." }
                } else if url.host == "today" {
                    tab = 0
                } else if url.host == "open", let section = AppSection(rawValue: url.lastPathComponent) {
                    open(section)
                } else if url.host == "live" {
                    // Tapped the Dynamic Island or Lock Screen activity.
                    if url.path == "/run" {
                        if RunTracker.shared.screens == 0 { showRun = true }
                    } else if store.activeWorkout == nil {
                        tab = 0
                    }
                } else if url.host == "w" {
                    calendarMessage = "That workout link is broken or incomplete."
                }
            } else if url.pathExtension.lowercased() == "ics" {
                calendarMessage = store.importCalendar(from: url)
            } else if url.pathExtension.lowercased() == "json", let raw = try? Data(contentsOf: url) {
                calendarMessage = store.importBackup(raw) ? "Backup restored." : "That file isn't an Edgework backup."
            }
        }
        .alert(calendarMessage ?? "", isPresented: Binding(get: { calendarMessage != nil }, set: { if !$0 { calendarMessage = nil } })) {
            Button("OK", role: .cancel) {}
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                store.ensureToday()
                Notifier.reschedule(store)
                if !store.data.settings.calendarURL.isEmpty,
                   Date().timeIntervalSince(store.data.lastSync ?? .distantPast) > 1800 {
                    Task { _ = await store.syncCalendar() }
                }
            case .background, .inactive: store.saveNow()
            @unknown default: break
            }
        }
    }
}

extension RootView {
    /// Runs whatever Siri (or a Shortcut) asked for, once.
    func handleSiri() {
        guard let action = siri.pending else { return }
        siri.pending = nil
        switch action {
        case .open(let section):
            open(section)
        case .startWorkout:
            store.ensureToday()
            tab = 0
            if store.activeWorkout == nil, let w = store.data.today?.workout { store.start(w) }
        case .logShots(let n):
            store.addShots(.wrist, n)
            calendarMessage = "Logged \(n) shots. \(store.daily().totalShots) of \(store.data.settings.shotGoal) today."
        case .logWater:
            store.updateDaily { $0.water += 1 }
            calendarMessage = "Logged a water. \(store.daily().water) of \(store.data.settings.waterGoal) today."
        }
    }

    func open(_ section: AppSection) {
        siriScreen = nil
        switch section {
        case .today: tab = 0
        case .train: tab = 1
        case .library: tab = 2
        case .food:
            if store.data.settings.showFuel { tab = 3 } else { siriScreen = .food }
        case .progress: tab = 4
        default: siriScreen = section
        }
    }
}

/// Launch-argument hooks used by the CI screenshot job (e.g. `-showScreen skater-bound`).
private struct DebugScreen: Identifiable {
    let id: String
}
