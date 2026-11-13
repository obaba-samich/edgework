import SwiftUI

@main
struct EdgeworkApp: App {
    @StateObject private var store = Store()

    init() { Appearance.apply() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Theme.ice)
        }
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
    @State private var tab = UserDefaults.standard.integer(forKey: "startTab")
    @State private var debugSheet = UserDefaults.standard.string(forKey: "showScreen")
    @State private var calendarMessage: String?

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
            if UserDefaults.standard.bool(forKey: "autoStart"), let w = store.data.today?.workout { store.start(w) }
        }
        .onOpenURL { url in
            if url.pathExtension.lowercased() == "ics" {
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

/// Launch-argument hooks used by the CI screenshot job (e.g. `-showScreen skater-bound`).
private struct DebugScreen: Identifiable {
    let id: String
}
