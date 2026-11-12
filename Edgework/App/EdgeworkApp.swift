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
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = UserDefaults.standard.integer(forKey: "startTab")
    @State private var debugSheet = UserDefaults.standard.string(forKey: "showScreen")
    @State private var calendarMessage: String?

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "figure.hockey") }
                .tag(0)
            TrainView()
                .tabItem { Label("Train", systemImage: "square.stack.3d.up.fill") }
                .tag(1)
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                .tag(2)
            FuelView()
                .tabItem { Label("Fuel", systemImage: "fork.knife") }
                .tag(3)
            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                .tag(4)
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
