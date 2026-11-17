import AppIntents
import SwiftUI

/// Places in the app Siri can open.
enum AppSection: String, AppEnum {
    case today, train, library, food, progress, shooting, stickhandling, running, study, settings

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Section"
    static var caseDisplayRepresentations: [AppSection: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "Today", synonyms: ["home", "today's workout", "my workout"]),
        .train: DisplayRepresentation(title: "Train", synonyms: ["training", "workouts", "programs"]),
        .library: DisplayRepresentation(title: "Library", synonyms: ["exercises", "exercise library"]),
        .food: DisplayRepresentation(title: "Food", synonyms: ["fuel", "nutrition", "meals", "food log", "diet"]),
        .progress: DisplayRepresentation(title: "Progress", synonyms: ["stats", "my stats", "history"]),
        .shooting: DisplayRepresentation(title: "Shooting", synonyms: ["shots", "shot tracker", "aim trainer", "puck counter"]),
        .stickhandling: DisplayRepresentation(title: "Stickhandling", synonyms: ["hands", "stick handling"]),
        .running: DisplayRepresentation(title: "Running", synonyms: ["runs", "GPS run", "run tracker"]),
        .study: DisplayRepresentation(title: "Study", synonyms: ["learn exercises", "studying"]),
        .settings: DisplayRepresentation(title: "Settings", synonyms: ["profile", "preferences"]),
    ]
}

extension AppSection: Identifiable {
    var id: String { rawValue }
}

/// What a Siri request asked the app to do. RootView picks it up and acts on it.
enum SiriAction: Equatable {
    case open(AppSection)
    case startWorkout
    case logShots(Int)
    case logWater
}

@MainActor
final class SiriRouter: ObservableObject {
    static let shared = SiriRouter()
    @Published var pending: SiriAction?
}

struct OpenSectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Open a section"
    static var description = IntentDescription("Opens a part of Edgework, like Food, Shooting or Study.")
    static var openAppWhenRun = true

    @Parameter(title: "Section") var section: AppSection

    @MainActor
    func perform() async throws -> some IntentResult {
        SiriRouter.shared.pending = .open(section)
        return .result()
    }
}

struct StartWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Start today's workout"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SiriRouter.shared.pending = .startWorkout
        return .result()
    }
}

struct LogShotsIntent: AppIntent {
    static var title: LocalizedStringResource = "Log shots"
    static var description = IntentDescription("Adds wrist shots to today's shot count.")
    static var openAppWhenRun = true

    @Parameter(title: "Shots", requestValueDialog: "How many shots?") var count: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        SiriRouter.shared.pending = .logShots(max(0, min(1000, count)))
        return .result()
    }
}

struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a water"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SiriRouter.shared.pending = .logWater
        return .result()
    }
}

/// "Hey Siri, open food in Edgework", "Hey Siri, start my workout in Edgework"…
struct EdgeworkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenSectionIntent(), phrases: [
            "Open \(\.$section) in \(.applicationName)",
            "Open the \(\.$section) section in \(.applicationName)",
            "Open \(\.$section) on \(.applicationName)",
            "Go to \(\.$section) in \(.applicationName)",
            "Show \(\.$section) in \(.applicationName)",
            "Show my \(\.$section) in \(.applicationName)",
            "\(.applicationName) \(\.$section)",
        ], shortTitle: "Open a section", systemImageName: "square.grid.2x2")
        AppShortcut(intent: StartWorkoutIntent(), phrases: [
            "Start my workout in \(.applicationName)",
            "Start today's workout in \(.applicationName)",
            "Start a workout in \(.applicationName)",
            "\(.applicationName) start workout",
        ], shortTitle: "Start workout", systemImageName: "play.fill")
        AppShortcut(intent: LogShotsIntent(), phrases: [
            "Log shots in \(.applicationName)",
            "Add shots in \(.applicationName)",
            "Count shots in \(.applicationName)",
        ], shortTitle: "Log shots", systemImageName: "scope")
        AppShortcut(intent: LogWaterIntent(), phrases: [
            "Log water in \(.applicationName)",
            "Add a water in \(.applicationName)",
            "Drink water in \(.applicationName)",
        ], shortTitle: "Log water", systemImageName: "drop.fill")
    }
}
