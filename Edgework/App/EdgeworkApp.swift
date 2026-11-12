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
            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
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
                } else {
                    TodayWorkoutScreen()
                }
            }
            .environmentObject(store)
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "autoStart"), let w = store.data.today?.workout { store.start(w) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: store.ensureToday()
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
