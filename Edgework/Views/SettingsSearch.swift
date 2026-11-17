import Foundation

/// The Settings pages a search result can open.
enum SettingsPage: String, Identifiable {
    case workouts, warmup, running, hockey, track, goals, reminders, nutrition, features, during, schedule, data, sport
    var id: String { rawValue }

    var title: String {
        switch self {
        case .workouts: "Workouts"
        case .warmup: "Warm-up & line work"
        case .running: "Running & GPS"
        case .hockey: "Hockey"
        case .track: "Track & meets"
        case .goals: "Goals"
        case .reminders: "Reminders"
        case .nutrition: "Nutrition"
        case .features: "Features"
        case .during: "During workouts"
        case .schedule: "Schedule"
        case .data: "Data"
        case .sport: "Sport & units"
        }
    }
}

/// Screens a search result can open directly.
enum SettingsScreen: String, Identifiable {
    case mandatory, equipment, exclusions, adjustments, study, quiz, calendar, keywords, weekly, trainingTimes, routine, lineMoves, nutritionProfile, trackEvents
    var id: String { rawValue }
}

/// One searchable setting: what it's called, where it lives, and other words people might type for it.
struct SettingsSearchItem: Identifiable {
    enum Target { case page(SettingsPage), screen(SettingsScreen) }

    let title: String
    let place: String
    let target: Target
    let keywords: [String]
    /// nil = both sports.
    var sport: Sport? = nil
    var id: String { place + title }

    func matches(_ query: String) -> Bool {
        let hay = ([title, place] + keywords).joined(separator: " ").lowercased()
        let words = query.lowercased().split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
        return !words.isEmpty && words.allSatisfy { hay.contains($0) }
    }

    static let all: [SettingsSearchItem] = [
        // Sport & units
        .init(title: "Sport", place: "Sport & units", target: .page(.sport), keywords: ["hockey", "track", "field", "switch sport", "athletics"]),
        .init(title: "Units", place: "Sport & units", target: .page(.sport), keywords: ["imperial", "metric", "miles", "km", "kilometres", "pounds", "lb", "kg", "weight", "distance"]),
        .init(title: "Your name", place: "Profile", target: .page(.sport), keywords: ["name", "profile", "initials"]),

        // Workouts
        .init(title: "Training style", place: "Workouts › Player", target: .page(.workouts), keywords: ["style", "power", "speed", "balanced"], sport: .hockey),
        .init(title: "Position", place: "Workouts › Player", target: .page(.workouts), keywords: ["forward", "defense", "defence", "goalie", "goaltender"], sport: .hockey),
        .init(title: "Season phase", place: "Workouts", target: .page(.workouts), keywords: ["season", "off-season", "preseason", "in-season", "playoffs", "phase"]),
        .init(title: "Default length", place: "Workouts", target: .page(.workouts), keywords: ["duration", "minutes", "how long", "time", "length"]),
        .init(title: "Rest periods", place: "Workouts", target: .page(.workouts), keywords: ["rest", "short", "long", "between sets", "recovery time"]),
        .init(title: "Global intensity", place: "Workouts", target: .page(.workouts), keywords: ["intensity", "harder", "easier", "volume", "reps", "scale", "percent"]),
        .init(title: "Review before starting", place: "Workouts", target: .page(.workouts), keywords: ["review", "preview", "check", "edit before", "list"]),
        .init(title: "Rebuild today's workout", place: "Workouts", target: .page(.workouts), keywords: ["regenerate", "new workout", "refresh", "reset today"]),
        .init(title: "Hardest exercises", place: "Workouts › Difficulty", target: .page(.workouts), keywords: ["difficulty", "beginner", "intermediate", "advanced", "level", "hard"]),
        .init(title: "Exercises I know", place: "Workouts › Difficulty", target: .page(.workouts), keywords: ["knowledge", "familiar", "classics", "know", "level", "specialised", "specialized"]),
        .init(title: "Exercises I know quick test", place: "Workouts › Difficulty", target: .screen(.quiz), keywords: ["quiz", "test", "which do I know", "familiar"]),
        .init(title: "Study new exercises", place: "Workouts › Difficulty", target: .screen(.study), keywords: ["study", "learn", "learned", "new moves", "teach"]),
        .init(title: "Mandatory exercises", place: "Workouts › Difficulty", target: .screen(.mandatory), keywords: ["must-dos", "must do", "required", "always", "every workout", "mandatory"]),
        .init(title: "Extra sets", place: "Workouts › Difficulty", target: .page(.workouts), keywords: ["sets", "more sets", "fewer sets", "volume"]),
        .init(title: "Low impact (no jumping)", place: "Workouts › Difficulty", target: .page(.workouts), keywords: ["low impact", "no jumping", "jumps", "joints", "knees", "quiet", "apartment", "plyometrics"]),
        .init(title: "Never show these", place: "Workouts › Difficulty", target: .screen(.exclusions), keywords: ["exclude", "hide", "ban", "block", "remove exercise", "never", "don't show"]),
        .init(title: "Per-exercise adjustments", place: "Workouts › Difficulty", target: .screen(.adjustments), keywords: ["adjust", "easier", "harder", "percent", "factor", "scale exercise"]),
        .init(title: "Equipment I have", place: "Workouts › Difficulty", target: .screen(.equipment), keywords: ["equipment", "gear", "dumbbells", "bands", "kettlebell", "barbell", "box", "hill", "stick", "pucks"]),

        // Warm-up & lines
        .init(title: "Warm-up type", place: "Warm-up & line work", target: .page(.warmup), keywords: ["warm-up", "warmup", "auto", "routine", "none", "dynamic"]),
        .init(title: "My warm-up routine", place: "Warm-up & line work", target: .screen(.routine), keywords: ["routine", "team warm-up", "own warm-up", "custom warm-up"]),
        .init(title: "Dynamic moves & static stretches", place: "Warm-up & line work", target: .page(.warmup), keywords: ["stretches", "stretching", "dynamic", "static", "count"]),
        .init(title: "Cool-down stretches", place: "Warm-up & line work", target: .page(.warmup), keywords: ["cool-down", "cooldown", "stretch", "after"]),
        .init(title: "Count travelling moves in lines", place: "Warm-up & line work", target: .page(.warmup), keywords: ["lines", "line mode", "rink", "field", "travel", "high knees", "carioca"]),
        .init(title: "Lines per set", place: "Warm-up & line work", target: .page(.warmup), keywords: ["lines", "count", "length"]),
        .init(title: "Per-exercise line choices", place: "Warm-up & line work", target: .screen(.lineMoves), keywords: ["lines", "time", "reps", "measure"]),

        // Running
        .init(title: "Runs in workouts", place: "Running & GPS", target: .page(.running), keywords: ["jog", "warm-up jog", "run finisher", "running", "cardio"]),
        .init(title: "Include Run Days", place: "Running & GPS", target: .page(.running), keywords: ["run days", "running days", "rotation"]),
        .init(title: "GPS auto-pause", place: "Running & GPS", target: .page(.running), keywords: ["gps", "auto pause", "stop", "pause"]),
        .init(title: "Announce each mile or kilometre", place: "Running & GPS", target: .page(.running), keywords: ["voice", "announce", "splits", "speak", "audio", "mile", "km"]),

        // Sport pages
        .init(title: "Pucks I have", place: "Hockey", target: .page(.hockey), keywords: ["pucks", "bucket", "puck counter", "shooting"], sport: .hockey),
        .init(title: "Hockey drills in workouts", place: "Hockey", target: .page(.hockey), keywords: ["stickhandling", "shooting", "drills", "hockey"], sport: .hockey),
        .init(title: "Hockey skill tools on Train", place: "Hockey", target: .page(.hockey), keywords: ["tools", "shooting", "stickhandling", "hands caller", "train tab"], sport: .hockey),
        .init(title: "Event group", place: "Track & meets", target: .page(.track), keywords: ["sprints", "hurdles", "jumps", "throws", "distance", "events"], sport: .track),
        .init(title: "My events", place: "Track & meets", target: .screen(.trackEvents), keywords: ["events", "100", "200", "long jump", "shot put", "hurdles"], sport: .track),
        .init(title: "Day before, meet day, day after", place: "Track & meets", target: .page(.track), keywords: ["meet", "taper", "recovery", "rest", "light"], sport: .track),
        .init(title: "Hand-timed marks", place: "Track & meets", target: .page(.track), keywords: ["hand timed", "fat", "marks", "times", "stopwatch"], sport: .track),

        // Goals
        .init(title: "Water goal", place: "Goals", target: .page(.goals), keywords: ["water", "glasses", "hydration", "drink"]),
        .init(title: "Weekly running goal", place: "Goals", target: .page(.goals), keywords: ["running", "distance", "km", "miles", "weekly"]),
        .init(title: "Shots per day", place: "Goals", target: .page(.goals), keywords: ["shots", "shot goal", "shooting", "pucks"], sport: .hockey),
        .init(title: "Stickhandling minutes", place: "Goals", target: .page(.goals), keywords: ["stickhandling", "hands", "minutes", "stick"], sport: .hockey),

        // Schedule
        .init(title: "Team or track calendar", place: "Schedule", target: .screen(.calendar), keywords: ["calendar", "games", "meets", "practices", "teamsnap", "ics", "sync", "schedule"]),
        .init(title: "Calendar keywords", place: "Schedule", target: .screen(.keywords), keywords: ["keywords", "words", "game", "practice", "ignore", "sort events"]),
        .init(title: "Keep normal workouts on game/meet days", place: "Schedule", target: .page(.schedule), keywords: ["game day", "meet day", "normal workout", "activation"]),
        .init(title: "Lighter workouts after events", place: "Schedule", target: .page(.schedule), keywords: ["after game", "lighter", "recovery", "adjust"]),
        .init(title: "Game or meet icons on the week", place: "Schedule", target: .page(.schedule), keywords: ["icons", "week", "calendar strip"]),
        .init(title: "Rest days", place: "Schedule", target: .page(.schedule), keywords: ["rest", "days off", "off day", "stretch only"]),
        .init(title: "Repeating weekly days", place: "Schedule", target: .screen(.weekly), keywords: ["weekly", "repeat", "every week", "game days", "practice days"]),

        // Reminders
        .init(title: "Workout reminders", place: "Reminders", target: .page(.reminders), keywords: ["notifications", "reminder", "alert", "remind", "workout time"]),
        .init(title: "Times for each day", place: "Reminders", target: .screen(.trainingTimes), keywords: ["time", "schedule", "training time", "per day"]),
        .init(title: "Streak saver", place: "Reminders", target: .page(.reminders), keywords: ["streak", "notification", "evening", "haven't trained"]),
        .init(title: "Shot goal nudge", place: "Reminders", target: .page(.reminders), keywords: ["shots", "nudge", "notification", "shot goal"], sport: .hockey),
        .init(title: "Run reminders", place: "Reminders", target: .page(.reminders), keywords: ["run", "running", "notification", "run days"]),
        .init(title: "Water reminders", place: "Reminders", target: .page(.reminders), keywords: ["water", "hydration", "drink", "notification"]),
        .init(title: "Game day reminder", place: "Reminders", target: .page(.reminders), keywords: ["game", "puck drop", "activation", "notification"], sport: .hockey),
        .init(title: "Meet day and warm-up reminders", place: "Reminders", target: .page(.reminders), keywords: ["meet", "warm-up", "notification"], sport: .track),

        // App
        .init(title: "Nutrition profile", place: "Nutrition", target: .screen(.nutritionProfile), keywords: ["calories", "kcal", "protein", "macros", "weight", "height", "age", "diet", "food", "goal"]),
        .init(title: "Fuel tab", place: "Features", target: .page(.features), keywords: ["food", "fuel", "nutrition", "meals", "hide tab"]),
        .init(title: "Meal generator", place: "Features", target: .page(.features), keywords: ["meals", "food ideas", "recipes"]),
        .init(title: "Daily readiness check-in", place: "Features", target: .page(.features), keywords: ["readiness", "check-in", "sleep", "soreness", "how do you feel"]),
        .init(title: "Daily goals card", place: "Features", target: .page(.features), keywords: ["goals", "rings", "today card"]),
        .init(title: "Coach's tips", place: "Features", target: .page(.features), keywords: ["tips", "advice", "coach"]),

        // During workouts
        .init(title: "Haptics", place: "During workouts", target: .page(.during), keywords: ["vibration", "vibrate", "haptic", "feedback"]),
        .init(title: "Sounds", place: "During workouts", target: .page(.during), keywords: ["sound", "beep", "audio", "mute"]),
        .init(title: "3-2-1 countdown", place: "During workouts", target: .page(.during), keywords: ["countdown", "beeps", "timer"]),
        .init(title: "Rest timer between sets", place: "During workouts", target: .page(.during), keywords: ["rest", "breathe", "breathing", "timer", "break", "pause between"]),
        .init(title: "Auto-start after rest", place: "During workouts", target: .page(.during), keywords: ["auto advance", "auto start", "next set", "automatic"]),
        .init(title: "Keep the screen on", place: "During workouts", target: .page(.during), keywords: ["screen", "awake", "sleep", "lock", "display"]),
        .init(title: "Live Activity & Dynamic Island", place: "During workouts", target: .page(.during), keywords: ["dynamic island", "lock screen", "live activity", "timer"]),
        .init(title: "Coaching cues", place: "During workouts", target: .page(.during), keywords: ["cues", "tips", "form", "coaching"]),
        .init(title: "+ rest button", place: "During workouts", target: .page(.during), keywords: ["add rest", "more rest", "seconds"]),

        // Data
        .init(title: "Export backup", place: "Data", target: .page(.data), keywords: ["backup", "export", "save", "files", "transfer", "new phone"]),
        .init(title: "Import backup", place: "Data", target: .page(.data), keywords: ["restore", "import", "backup", "load"]),
        .init(title: "Run setup again", place: "Data", target: .page(.data), keywords: ["onboarding", "setup", "start over", "intro"]),
        .init(title: "Reset all data", place: "Data", target: .page(.data), keywords: ["erase", "delete", "reset", "wipe", "clear"]),
    ]
}
