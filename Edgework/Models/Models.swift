import SwiftUI

// MARK: - Exercise taxonomy

enum Category: String, Codable, CaseIterable, Identifiable {
    case warmup, lowerBody, upperBody, core, power, speed, conditioning, balance, mobility, stickhandling, shooting, goalie, running
    case sprints, hurdles, jumps, throwing

    static let hockeyOnly: Set<Category> = [.stickhandling, .shooting, .goalie]
    static let trackOnly: Set<Category> = [.sprints, .hurdles, .jumps, .throwing]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmup: "Warm-up"
        case .lowerBody: "Lower Body"
        case .upperBody: "Upper Body"
        case .core: "Core"
        case .power: "Power & Plyo"
        case .speed: "Speed & Agility"
        case .conditioning: "Conditioning"
        case .balance: "Balance"
        case .mobility: "Mobility"
        case .stickhandling: "Stickhandling"
        case .shooting: "Shooting"
        case .goalie: "Goalie"
        case .running: "Running"
        case .sprints: "Sprints"
        case .hurdles: "Hurdles"
        case .jumps: "Jumps"
        case .throwing: "Throws"
        }
    }

    var symbol: String {
        switch self {
        case .warmup: "flame"
        case .lowerBody: "figure.strengthtraining.functional"
        case .upperBody: "dumbbell.fill"
        case .core: "figure.core.training"
        case .power: "bolt.fill"
        case .speed: "hare.fill"
        case .conditioning: "heart.fill"
        case .balance: "figure.mind.and.body"
        case .mobility: "figure.flexibility"
        case .stickhandling: "figure.hockey"
        case .shooting: "scope"
        case .goalie: "shield.lefthalf.filled"
        case .running: "figure.run"
        case .sprints: "figure.track.and.field"
        case .hurdles: "figure.step.training"
        case .jumps: "arrow.up.forward"
        case .throwing: "circle.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .warmup: Color(hex: 0xFFB547)
        case .lowerBody: Color(hex: 0x5B8CFF)
        case .upperBody: Color(hex: 0x9B86FF)
        case .core: Color(hex: 0xFF8A5B)
        case .power: Color(hex: 0xFF4D5E)
        case .speed: Color(hex: 0x7CD4FF)
        case .conditioning: Color(hex: 0xFF5FA2)
        case .balance: Color(hex: 0x4FD1C5)
        case .mobility: Color(hex: 0x3DDC97)
        case .stickhandling: Color(hex: 0xF5D76E)
        case .shooting: Color(hex: 0xB8F36B)
        case .goalie: Color(hex: 0xB7C4D6)
        case .running: Color(hex: 0x22D3EE)
        case .sprints: Color(hex: 0xFF6B5E)
        case .hurdles: Color(hex: 0xFFB547)
        case .jumps: Color(hex: 0x9B86FF)
        case .throwing: Color(hex: 0x3DDC97)
        }
    }

    /// Default rest between sets, in seconds.
    var defaultRest: Int {
        switch self {
        case .warmup: 5
        case .lowerBody, .upperBody: 60
        case .core: 30
        case .power: 75
        case .speed: 60
        case .conditioning: 45
        case .balance: 20
        case .mobility: 5
        case .stickhandling: 20
        case .shooting: 30
        case .goalie: 40
        case .running: 90
        case .sprints: 150
        case .hurdles: 90
        case .jumps: 90
        case .throwing: 75
        }
    }

    /// Order inside a session: nervous-system-heavy work first, fatigue work last.
    var sessionRank: Int {
        switch self {
        case .warmup: 0
        case .power: 1
        case .speed: 2
        case .goalie: 3
        case .stickhandling: 4
        case .shooting: 5
        case .lowerBody: 6
        case .upperBody: 7
        case .balance: 8
        case .core: 9
        case .conditioning: 10
        case .running: 10
        case .sprints: 1
        case .hurdles: 2
        case .jumps: 2
        case .throwing: 3
        case .mobility: 11
        }
    }
}

enum Muscle: String, Codable, CaseIterable, Identifiable {
    case chest, shoulders, biceps, triceps, forearms, upperBack, lats, lowerBack
    case abs, obliques, hipFlexors, glutes, adductors, abductors, quads, hamstrings, calves

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chest: "Chest"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .forearms: "Forearms & Grip"
        case .upperBack: "Upper Back"
        case .lats: "Lats"
        case .lowerBack: "Lower Back"
        case .abs: "Abs"
        case .obliques: "Obliques"
        case .hipFlexors: "Hip Flexors"
        case .glutes: "Glutes"
        case .adductors: "Adductors (Groin)"
        case .abductors: "Hip Abductors"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .calves: "Calves"
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case dumbbells, kettlebell, band, barbell, bench, box, medBall, pullupBar, jumpRope, cones, foamRoller, slideBoard, stickBall, shootingPad, tennisBall

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dumbbells: "Dumbbells"
        case .kettlebell: "Kettlebell"
        case .band: "Resistance Band"
        case .barbell: "Barbell & Rack"
        case .bench: "Bench / Chair"
        case .box: "Plyo Box / Step"
        case .medBall: "Medicine Ball"
        case .pullupBar: "Pull-up Bar"
        case .jumpRope: "Jump Rope"
        case .cones: "Cones / Markers"
        case .foamRoller: "Foam Roller"
        case .slideBoard: "Slide Board"
        case .stickBall: "Stick & Ball"
        case .shootingPad: "Shooting Pad & Net"
        case .tennisBall: "Tennis Ball & Wall"
        }
    }

    var symbol: String {
        switch self {
        case .dumbbells: "dumbbell.fill"
        case .kettlebell: "scalemass.fill"
        case .band: "point.topleft.down.to.point.bottomright.curvepath"
        case .barbell: "figure.strengthtraining.traditional"
        case .bench: "chair.lounge.fill"
        case .box: "shippingbox.fill"
        case .medBall: "circle.fill"
        case .pullupBar: "figure.climbing"
        case .jumpRope: "figure.jumprope"
        case .cones: "cone.fill"
        case .foamRoller: "cylinder.fill"
        case .slideBoard: "figure.ice.skating"
        case .stickBall: "figure.hockey"
        case .shootingPad: "sportscourt.fill"
        case .tennisBall: "tennisball.fill"
        }
    }

    static let defaults: Set<Equipment> = [.dumbbells, .band, .bench, .jumpRope, .stickBall, .tennisBall, .cones]
}

enum Measure: String, Codable {
    case reps, seconds, meters, lines

    func label(_ value: Int) -> String {
        switch self {
        case .reps: return value == 1 ? "rep" : "reps"
        case .seconds: return "sec"
        case .meters: return "m"
        case .lines: return value == 1 ? "line" : "lines"
        }
    }

    func format(_ value: Int) -> String {
        switch self {
        case .reps: return "\(value)"
        case .seconds: return value >= 60 && value % 60 == 0 ? "\(value / 60):00" : (value >= 60 ? String(format: "%d:%02d", value / 60, value % 60) : "\(value)s")
        case .lines: return "\(value) \(value == 1 ? "line" : "lines")"
        case .meters: return value >= 1000 ? String(format: "%.1fkm", Double(value) / 1000) : "\(value)m"
        }
    }

    /// Rounds a scaled value to something you'd actually count.
    func round(_ raw: Double) -> Int {
        switch self {
        case .reps, .lines: return max(1, Int(raw.rounded()))
        case .seconds: return max(5, Int((raw / 5).rounded()) * 5)
        case .meters: return raw >= 1000 ? max(50, Int((raw / 50).rounded()) * 50) : max(5, Int((raw / 5).rounded()) * 5)
        }
    }
}

enum Tag: String, Hashable {
    case cooldown, injuryPrevention, explosive, gameDay, noSpace, staticStretch, walking
}

struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let category: Category
    let measure: Measure
    let sets: Int
    let base: Int
    let perSide: Bool
    let level: Int
    let primary: [Muscle]
    let secondary: [Muscle]
    let equipment: [Equipment]
    let symbol: String
    let tags: Set<Tag>
    let summary: String
    let steps: [String]
    let cues: [String]
    let why: String

    var levelTitle: String { ["Beginner", "Intermediate", "Advanced"][max(0, min(2, level - 1))] }

    func defaultTarget() -> String {
        "\(sets) × \(measure.format(base))\(perSide ? " / side" : "")"
    }
}

// MARK: - Workouts

enum Block: String, Codable, CaseIterable, Identifiable {
    case warmup, stretch, main, musts, finisher, cooldown
    var id: String { rawValue }
    var title: String {
        switch self {
        case .warmup: "Warm-up"
        case .stretch: "Static Stretch"
        case .main: "Main Set"
        case .musts: "Must-Dos"
        case .finisher: "Finisher"
        case .cooldown: "Cool-down"
        }
    }
}

enum Focus: String, Codable, CaseIterable, Identifiable {
    case activation, power, strength, speed, conditioning, core, hands, fullBody, goalie, mobility, recovery, custom
    case upper, legs, abs, hiit, run
    case trackSpeed, speedEndurance, tempo, hurdleDay, jumpDay, throwDay, distance

    static let track: [Focus] = [.trackSpeed, .speedEndurance, .tempo, .hurdleDay, .jumpDay, .throwDay, .distance]
    static let hockeyOnly: [Focus] = [.hands, .goalie]

    var id: String { rawValue }

    static let generatable: [Focus] = [.fullBody, .upper, .legs, .abs, .hiit, .run, .strength, .power, .speed, .conditioning, .core, .hands, .goalie, .mobility, .recovery, .activation]

    static func generatable(for sport: Sport) -> [Focus] {
        sport == .track
            ? track + [.strength, .power, .fullBody, .upper, .legs, .abs, .hiit, .core, .mobility, .recovery, .activation]
            : generatable
    }

    var title: String {
        switch self {
        case .activation: "Pre-Game Activation"
        case .power: "Explosive Power"
        case .strength: "Strength"
        case .speed: "Speed & Agility"
        case .conditioning: "Shift Conditioning"
        case .core: "Core & Stability"
        case .hands: "Hands & Shot"
        case .fullBody: "Full Body"
        case .goalie: "Goalie Athleticism"
        case .mobility: "Mobility"
        case .recovery: "Recovery Flush"
        case .custom: "Custom"
        case .upper: "Upper Body"
        case .legs: "Leg Day"
        case .abs: "Abs & Core Burn"
        case .hiit: "HIIT"
        case .run: "Run Day"
        case .trackSpeed: "Speed Day"
        case .speedEndurance: "Speed Endurance"
        case .tempo: "Tempo Run"
        case .hurdleDay: "Hurdle Day"
        case .jumpDay: "Jumps Day"
        case .throwDay: "Throws Day"
        case .distance: "Distance Day"
        }
    }

    var shortTitle: String {
        switch self {
        case .activation: "Activation"
        case .power: "Power"
        case .strength: "Strength"
        case .speed: "Speed"
        case .conditioning: "Conditioning"
        case .core: "Core"
        case .hands: "Hands"
        case .fullBody: "Full Body"
        case .goalie: "Goalie"
        case .mobility: "Mobility"
        case .recovery: "Recovery"
        case .custom: "Custom"
        case .upper: "Upper"
        case .legs: "Legs"
        case .abs: "Abs"
        case .hiit: "HIIT"
        case .run: "Run"
        case .trackSpeed: "Speed"
        case .speedEndurance: "Speed End."
        case .tempo: "Tempo"
        case .hurdleDay: "Hurdles"
        case .jumpDay: "Jumps"
        case .throwDay: "Throws"
        case .distance: "Distance"
        }
    }

    var tagline: String {
        switch self {
        case .activation: "Wake the legs up, stay fresh for puck drop."
        case .power: "First-step explosiveness and a harder stride."
        case .strength: "Build the base that wins board battles."
        case .speed: "Quick feet, sharp cuts, faster transitions."
        case .conditioning: "Repeatable 45-second shifts, fast recovery."
        case .core: "Anti-rotation and balance for shooting and contact."
        case .hands: "Soft hands, eyes up, quicker release."
        case .fullBody: "A bit of everything. Total athlete day."
        case .goalie: "Hips, reactions and lateral power."
        case .mobility: "Hips, groin and back that move like they should."
        case .recovery: "Flush the legs and bounce back for the next game."
        case .custom: "Your own build."
        case .upper: "Chest, back, shoulders and arms."
        case .legs: "Squats, lunges, hinges. Build the engine."
        case .abs: "Crunches, holds and twists. Feel the burn."
        case .hiit: "Short, sweaty intervals. Heart rate up."
        case .run: "Strides, intervals and distance."
        case .trackSpeed: "Drills, starts and max-velocity sprints."
        case .speedEndurance: "Hold your speed deep into the race."
        case .tempo: "Smooth, controlled runs to build your engine."
        case .hurdleDay: "Mobility, rhythm and hurdle technique."
        case .jumpDay: "Approach, takeoff and reactive power."
        case .throwDay: "Explosive hips and rotational power."
        case .distance: "Easy miles and aerobic base."
        }
    }

    var symbol: String {
        switch self {
        case .activation: "flag.checkered"
        case .power: "bolt.fill"
        case .strength: "figure.strengthtraining.traditional"
        case .speed: "hare.fill"
        case .conditioning: "heart.fill"
        case .core: "figure.core.training"
        case .hands: "figure.hockey"
        case .fullBody: "figure.cross.training"
        case .goalie: "shield.lefthalf.filled"
        case .mobility: "figure.flexibility"
        case .recovery: "leaf.fill"
        case .custom: "slider.horizontal.3"
        case .upper: "dumbbell.fill"
        case .legs: "figure.strengthtraining.functional"
        case .abs: "figure.core.training"
        case .hiit: "flame.fill"
        case .run: "figure.run"
        case .trackSpeed: "figure.track.and.field"
        case .speedEndurance: "stopwatch.fill"
        case .tempo: "metronome.fill"
        case .hurdleDay: "figure.step.training"
        case .jumpDay: "arrow.up.forward"
        case .throwDay: "circle.circle.fill"
        case .distance: "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .activation: Color(hex: 0xFFB547)
        case .power: Color(hex: 0xFF4D5E)
        case .strength: Color(hex: 0x5B8CFF)
        case .speed: Color(hex: 0x7CD4FF)
        case .conditioning: Color(hex: 0xFF5FA2)
        case .core: Color(hex: 0xFF8A5B)
        case .hands: Color(hex: 0xF5D76E)
        case .fullBody: Color(hex: 0x9B86FF)
        case .goalie: Color(hex: 0xB7C4D6)
        case .mobility: Color(hex: 0x3DDC97)
        case .recovery: Color(hex: 0x4FD1C5)
        case .custom: Color(hex: 0x7CD4FF)
        case .upper: Color(hex: 0x9B86FF)
        case .legs: Color(hex: 0x5B8CFF)
        case .abs: Color(hex: 0xFF8A5B)
        case .hiit: Color(hex: 0xFF5FA2)
        case .run: Color(hex: 0x22D3EE)
        case .trackSpeed: Color(hex: 0xFF6B5E)
        case .speedEndurance: Color(hex: 0xFF4D5E)
        case .tempo: Color(hex: 0x22D3EE)
        case .hurdleDay: Color(hex: 0xFFB547)
        case .jumpDay: Color(hex: 0x9B86FF)
        case .throwDay: Color(hex: 0x3DDC97)
        case .distance: Color(hex: 0x7CD4FF)
        }
    }
}

struct WorkoutItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var exerciseID: String
    var sets: Int
    var base: Int
    var rest: Int
    var block: Block
    /// Fixed items (interval timer) ignore intensity scaling.
    var fixed: Bool = false

    var exercise: Exercise? { Library.byID[exerciseID] }
}

struct Workout: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var subtitle: String = ""
    var focus: Focus
    var items: [WorkoutItem]

    /// Items grouped in block order, preserving order inside each block.
    var ordered: [WorkoutItem] {
        Block.allCases.flatMap { b in items.filter { $0.block == b && $0.exercise != nil } }
    }

    var totalSets: Int { items.reduce(0) { $0 + $1.sets } }

    var mainCategories: [Category] {
        items.filter { $0.block == .main || $0.block == .finisher }.compactMap { $0.exercise?.category }
    }

    static let empty = Workout(title: "Workout", focus: .custom, items: [])
}

// MARK: - History

enum Feeling: String, Codable, CaseIterable {
    case easy, right, hard
    var title: String {
        switch self {
        case .easy: "Too easy"
        case .right: "Just right"
        case .hard: "Too hard"
        }
    }
    var symbol: String {
        switch self {
        case .easy: "arrow.up.circle.fill"
        case .right: "checkmark.circle.fill"
        case .hard: "arrow.down.circle.fill"
        }
    }
}

struct SessionEntry: Codable, Hashable {
    var exerciseID: String
    var sets: Int
    var value: Int
    var measure: Measure
}

struct SessionRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var title: String
    var focus: Focus
    var duration: Int
    var entries: [SessionEntry]
    var rpe: Int
    var feeling: Feeling
    var note: String
    var activity: Activity?
    var distance: Double?

    var minutes: Int { max(1, Int((Double(duration) / 60).rounded())) }
    var totalSets: Int { entries.reduce(0) { $0 + $1.sets } }
}

enum Activity: String, Codable, CaseIterable, Identifiable {
    case run, skate, practice, game, gym, bike, swim, sport, walk, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .run: "Run"
        case .skate: "Skate"
        case .practice: "Team practice"
        case .game: "Game"
        case .gym: "Gym session"
        case .bike: "Bike"
        case .swim: "Swim"
        case .sport: "Other sport"
        case .walk: "Walk / hike"
        case .other: "Other"
        }
    }
    var symbol: String {
        switch self {
        case .run: "figure.run"
        case .skate: "figure.ice.skating"
        case .practice: "figure.hockey"
        case .game: "flag.checkered"
        case .gym: "dumbbell.fill"
        case .bike: "figure.outdoor.cycle"
        case .swim: "figure.pool.swim"
        case .sport: "sportscourt.fill"
        case .walk: "figure.hiking"
        case .other: "star.fill"
        }
    }
    var hasDistance: Bool { self == .run || self == .bike || self == .swim || self == .walk }
}

// MARK: - Benchmarks

enum Benchmark: String, Codable, CaseIterable, Identifiable {
    case vertical, broadJump, sprint30, proAgility, plank, wallSit, pushups, pullups

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vertical: "Vertical Jump"
        case .broadJump: "Broad Jump"
        case .sprint30: "30 m Sprint"
        case .proAgility: "5-10-5 Shuttle"
        case .plank: "Plank Hold"
        case .wallSit: "Wall Sit"
        case .pushups: "Max Push-ups"
        case .pullups: "Max Pull-ups"
        }
    }

    var unit: String {
        switch self {
        case .vertical, .broadJump: "in"
        case .sprint30, .proAgility, .plank, .wallSit: "s"
        case .pushups, .pullups: "reps"
        }
    }

    var lowerIsBetter: Bool { self == .sprint30 || self == .proAgility }
    var decimals: Int {
        switch self {
        case .sprint30, .proAgility: 2
        case .vertical, .broadJump: 1
        default: 0
        }
    }

    var symbol: String {
        switch self {
        case .vertical: "arrow.up.to.line"
        case .broadJump: "arrow.right.to.line"
        case .sprint30: "hare.fill"
        case .proAgility: "arrow.left.arrow.right"
        case .plank: "figure.core.training"
        case .wallSit: "timer"
        case .pushups: "figure.strengthtraining.functional"
        case .pullups: "figure.climbing"
        }
    }

    var how: String {
        switch self {
        case .vertical: "Stand side-on to a wall, reach high and mark. Jump from a standstill and touch as high as you can. Score is the difference. Best of 3."
        case .broadJump: "Toes behind a line, swing arms and jump forward as far as you can. Stick the landing. Measure to the back of your rearmost heel. Best of 3."
        case .sprint30: "Mark 30 m. Start from a staggered stance, have someone time from first movement to crossing the line. Best of 2 with full rest."
        case .proAgility: "Three cones 5 yd apart. Start at the middle, sprint 5 to one side, 10 to the far side, 5 back through the middle. Best of each direction."
        case .plank: "Forearm plank, body in a straight line. Stop the clock when hips sag or rise noticeably."
        case .wallSit: "Back flat on a wall, thighs parallel to the floor, knees at 90°. Hands off your legs."
        case .pushups: "Chest to a fist-height target, full lockout, no rest at the top longer than 2 seconds."
        case .pullups: "Dead hang start, chin over bar, full extension each rep. No kipping."
        }
    }

    func format(_ v: Double) -> String { String(format: "%.\(decimals)f", v) }
}

struct BenchmarkEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var benchmark: Benchmark
    var date: Date
    var value: Double
}

// MARK: - Settings

enum Position: String, Codable, CaseIterable, Identifiable {
    case forward, defense, goalie
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum SeasonPhase: String, Codable, CaseIterable, Identifiable {
    case offseason, preseason, inseason, playoffs
    var id: String { rawValue }
    var title: String {
        switch self {
        case .offseason: "Off-season"
        case .preseason: "Pre-season"
        case .inseason: "In-season"
        case .playoffs: "Playoffs"
        }
    }
    var detail: String {
        switch self {
        case .offseason: "Most volume. Extra set on main lifts — build it up."
        case .preseason: "Full volume, sharpen speed and power."
        case .inseason: "Volume trimmed 15% so you stay fresh for games."
        case .playoffs: "Minimum effective dose. One less set, 30% less volume."
        }
    }
    var setsDelta: Int {
        switch self {
        case .offseason: 1
        case .preseason, .inseason: 0
        case .playoffs: -1
        }
    }
    var volume: Double {
        switch self {
        case .offseason, .preseason: 1.0
        case .inseason: 0.85
        case .playoffs: 0.7
        }
    }
}

enum RestLength: String, Codable, CaseIterable, Identifiable {
    case short, normal, long
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var multiplier: Double {
        switch self {
        case .short: 0.65
        case .normal: 1.0
        case .long: 1.4
        }
    }
}

enum DayType: String, Codable, CaseIterable, Identifiable {
    case game, postGame, practice, off
    var id: String { rawValue }
    var title: String {
        switch self {
        case .game: "Game Day"
        case .postGame: "Day After Game"
        case .practice: "Practice Day"
        case .off: "Training Day"
        }
    }
    var symbol: String {
        switch self {
        case .game: "flag.checkered"
        case .postGame: "leaf.fill"
        case .practice: "figure.ice.skating"
        case .off: "figure.strengthtraining.functional"
        }
    }
    var color: Color {
        switch self {
        case .game: Theme.red
        case .postGame: Color(hex: 0x4FD1C5)
        case .practice: Theme.ice
        case .off: Theme.text2
        }
    }
}

enum WarmupMode: String, Codable, CaseIterable, Identifiable {
    case auto, routine, none
    var id: String { rawValue }
    var title: String {
        switch self {
        case .auto: "Auto"
        case .routine: "My routine"
        case .none: "Skip"
        }
    }
}

enum RunMode: String, Codable, CaseIterable, Identifiable {
    case none, warmupJog, finisher, both
    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: "No runs"
        case .warmupJog: "Jog to warm up"
        case .finisher: "Run finisher"
        case .both: "Jog + run finisher"
        }
    }
}

enum TrainingStyle: String, Codable, CaseIterable, Identifiable {
    case mixed, general, hockey
    var id: String { rawValue }
    var title: String {
        switch self {
        case .mixed: "Mixed"
        case .general: "General fitness"
        case .hockey: "Hockey"
        }
    }
    var detail: String {
        switch self {
        case .mixed: "Rotates general workouts (upper, legs, abs, HIIT) with hockey days (power, speed, hands)."
        case .general: "Regular workouts: full body, upper, legs, abs, HIIT, mobility."
        case .hockey: "Hockey-focused days: strength, speed, power, conditioning, hands."
        }
    }
    /// Auto-focus rotation used when nothing on the calendar says otherwise.
    var rotation: [Focus] {
        switch self {
        case .mixed: [.fullBody, .power, .upper, .speed, .legs, .hiit, .abs, .conditioning, .mobility]
        case .general: [.fullBody, .upper, .legs, .hiit, .abs, .mobility]
        case .hockey: [.strength, .speed, .core, .power, .conditioning, .fullBody, .hands, .mobility]
        }
    }
}

enum EventKind: String, Codable, CaseIterable, Identifiable {
    case game, practice, meeting, skipped, ignore
    var id: String { rawValue }
    var title: String {
        switch self {
        case .game: "Game"
        case .practice: "Practice"
        case .meeting: "Meeting"
        case .skipped: "Not going"
        case .ignore: "Ignore"
        }
    }
    /// Only games and practices change the training day.
    var counts: Bool { self == .game || self == .practice }
    var symbol: String {
        switch self {
        case .game: "flag.checkered"
        case .practice: "figure.ice.skating"
        case .meeting: "person.3.fill"
        case .skipped: "calendar.badge.minus"
        case .ignore: "minus.circle"
        }
    }
    var color: Color {
        switch self {
        case .game: Theme.red
        case .practice: Theme.ice
        case .meeting: Theme.amber
        case .skipped: Theme.text3
        case .ignore: Theme.text3
        }
    }
}

struct CalEvent: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var start: Date
    var allDay: Bool
    var location: String
    var guessed: EventKind
    var end: Date?

    /// Best guess from the title. Order matters: ignore rules, goalie-only, games, meetings, then practices.
    static func guess(_ title: String, allDay: Bool = false, settings: Settings? = nil) -> EventKind {
        let t = " " + title.lowercased().replacingOccurrences(of: "/", with: " ") + " "
        func has(_ words: [String]) -> Bool { words.contains { t.contains($0) } }
        let extraIgnore = settings?.ignoreKeywords ?? []
        let extraPractice = settings?.practiceKeywords ?? []
        if has(["reminder", " tbd", "tba", "placeholder", " bye ", "no ice", "cancel", "postpone", "holiday", "off day"] + extraIgnore.map { $0.lowercased() }) { return .ignore }
        if has(["goalie", "goaltend"]) && !has([" vs", " @ ", "game"]) {
            return settings?.position == .goalie ? .practice : .ignore
        }
        let gameWords = ["game", " vs", "vs.", " v ", " @ ", " at ", "tournament", "scrimmage", "playoff", "championship", "exhibition", "jamboree", "final", "semi", "meet ", "invitational", "relays", "race"]
        if has(gameWords) { return allDay && (settings?.allDayIgnore ?? true) ? .ignore : .game }
        if has(["meeting", "parent", "photo", "picture", "fundraiser", "banquet", "party", "registration", "dinner", "social", "volunteer", "orientation", "zoom", "jersey", "uniform", "info session", "sign up", "signup", "team bonding", "potluck"]) {
            return .meeting
        }
        let practiceWords = ["practice", "skate", "skills", "clinic", "training", "dryland", "camp", "tryout", "development", "stick time", "stick & puck", "stick and puck", " solo", "shared", " ice ", "ice time", "power skating", "workout", "conditioning", "lift"]
        if has(practiceWords + extraPractice.map { $0.lowercased() }) { return allDay ? .ignore : .practice }
        // Team ice codes like "B2", "A1", "12U", "xxU b1".
        if t.range(of: #"\b([abc][0-9]|[0-9]{1,2}u|xxu)\b"#, options: .regularExpression) != nil { return allDay ? .ignore : .practice }
        return .ignore
    }
}

enum Sport: String, Codable, CaseIterable, Identifiable {
    case hockey, track
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hockey: "Hockey"
        case .track: "Track & Field"
        }
    }
    var symbol: String {
        switch self {
        case .hockey: "figure.hockey"
        case .track: "figure.track.and.field"
        }
    }
}

enum TrackGroup: String, Codable, CaseIterable, Identifiable {
    case sprints, hurdles, distance, jumps, throwing, multi
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sprints: "Sprints"
        case .hurdles: "Hurdles"
        case .distance: "Distance"
        case .jumps: "Jumps"
        case .throwing: "Throws"
        case .multi: "Multi-events"
        }
    }
    var rotation: [Focus] {
        switch self {
        case .sprints: [.trackSpeed, .strength, .tempo, .power, .speedEndurance, .core, .mobility]
        case .hurdles: [.hurdleDay, .trackSpeed, .strength, .tempo, .power, .speedEndurance, .mobility]
        case .distance: [.distance, .tempo, .strength, .distance, .speedEndurance, .core, .mobility]
        case .jumps: [.jumpDay, .trackSpeed, .power, .strength, .tempo, .core, .mobility]
        case .throwing: [.throwDay, .strength, .power, .throwDay, .trackSpeed, .core, .mobility]
        case .multi: [.trackSpeed, .hurdleDay, .jumpDay, .throwDay, .strength, .tempo, .mobility]
        }
    }
}

struct TrackPR: Codable, Identifiable, Hashable {
    var id = UUID()
    var event: String
    var date: Date
    var value: Double
    var note: String = ""
}

struct Settings: Codable {
    var name = ""
    var position = Position.forward
    var phase = SeasonPhase.inseason
    var duration = 30
    var rest = RestLength.normal
    var intensity = 1.0
    var equipment: Set<Equipment> = Equipment.defaults
    var gameDays: Set<Int> = []
    var practiceDays: Set<Int> = []
    var style = TrainingStyle.mixed
    var calendarURL = ""
    var warmupMode = WarmupMode.auto
    var warmupRoutine: [WorkoutItem] = []
    var warmupCount = 5
    var stretchCount = 3
    var cooldownCount = 2
    var runMode = RunMode.none
    var runDays = true
    var extraSets = 0
    var maxLevel = 3
    var includeHockey = true
    var lowImpact = false
    var excluded: Set<String> = []
    var reviewFirst = true
    var remindDaily = false
    var remindMinute = 17 * 60
    var remindGame = true
    var remindStreak = false
    var autoAdvance = true
    var lineMode = true
    var puckCount = 18
    var sport = Sport.hockey
    var trackGroup = TrackGroup.sprints
    var normalOnEventDays = false
    var adjustAfterEvents = true
    var ignoreKeywords: [String] = []
    var practiceKeywords: [String] = []
    var hidePastEvents = true
    var allDayIgnore = true
    var showFuel = true
    var showMealGenerator = true
    var showReadiness = true
    var showDailyGoals = true
    var showFigures = true
    var showTips = true
    var showHockeyTools = true
    var lineCount = 2
    var measureModes: [String: String] = [:]
    var trainTimes: [String: Int] = [:]
    var runRemind = false
    var runRemindDays: Set<Int> = []
    var runMinute = 7 * 60
    var remindWater = false
    var shotGoal = 100
    var stickGoal = 15
    var waterGoal = 8
    var runGoalKm = 10.0
    var mustDos: [WorkoutItem] = []
    var mustDosInPrograms = false
    var units = Units.imperial
    var weightKg = 70.0
    var heightCm = 175.0
    var age = 18
    var sex = Sex.male
    var nutritionGoal = NutritionGoal.maintain
    var kcalOverride = 0
    var proteinOverride = 0
    var haptics = true
    var sounds = true
    var countdown = true

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Settings()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? d.name
        position = try c.decodeIfPresent(Position.self, forKey: .position) ?? d.position
        phase = try c.decodeIfPresent(SeasonPhase.self, forKey: .phase) ?? d.phase
        duration = try c.decodeIfPresent(Int.self, forKey: .duration) ?? d.duration
        rest = try c.decodeIfPresent(RestLength.self, forKey: .rest) ?? d.rest
        intensity = try c.decodeIfPresent(Double.self, forKey: .intensity) ?? d.intensity
        equipment = try c.decodeIfPresent(Set<Equipment>.self, forKey: .equipment) ?? d.equipment
        gameDays = try c.decodeIfPresent(Set<Int>.self, forKey: .gameDays) ?? d.gameDays
        practiceDays = try c.decodeIfPresent(Set<Int>.self, forKey: .practiceDays) ?? d.practiceDays
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? d.haptics
        sounds = try c.decodeIfPresent(Bool.self, forKey: .sounds) ?? d.sounds
        countdown = try c.decodeIfPresent(Bool.self, forKey: .countdown) ?? d.countdown
        style = try c.decodeIfPresent(TrainingStyle.self, forKey: .style) ?? d.style
        calendarURL = try c.decodeIfPresent(String.self, forKey: .calendarURL) ?? d.calendarURL
        warmupMode = try c.decodeIfPresent(WarmupMode.self, forKey: .warmupMode) ?? d.warmupMode
        warmupRoutine = try c.decodeIfPresent([WorkoutItem].self, forKey: .warmupRoutine) ?? d.warmupRoutine
        warmupCount = try c.decodeIfPresent(Int.self, forKey: .warmupCount) ?? d.warmupCount
        stretchCount = try c.decodeIfPresent(Int.self, forKey: .stretchCount) ?? d.stretchCount
        cooldownCount = try c.decodeIfPresent(Int.self, forKey: .cooldownCount) ?? d.cooldownCount
        runMode = try c.decodeIfPresent(RunMode.self, forKey: .runMode) ?? d.runMode
        runDays = try c.decodeIfPresent(Bool.self, forKey: .runDays) ?? d.runDays
        extraSets = try c.decodeIfPresent(Int.self, forKey: .extraSets) ?? d.extraSets
        maxLevel = try c.decodeIfPresent(Int.self, forKey: .maxLevel) ?? d.maxLevel
        includeHockey = try c.decodeIfPresent(Bool.self, forKey: .includeHockey) ?? d.includeHockey
        lowImpact = try c.decodeIfPresent(Bool.self, forKey: .lowImpact) ?? d.lowImpact
        excluded = try c.decodeIfPresent(Set<String>.self, forKey: .excluded) ?? d.excluded
        reviewFirst = try c.decodeIfPresent(Bool.self, forKey: .reviewFirst) ?? d.reviewFirst
        remindDaily = try c.decodeIfPresent(Bool.self, forKey: .remindDaily) ?? d.remindDaily
        remindMinute = try c.decodeIfPresent(Int.self, forKey: .remindMinute) ?? d.remindMinute
        remindGame = try c.decodeIfPresent(Bool.self, forKey: .remindGame) ?? d.remindGame
        remindStreak = try c.decodeIfPresent(Bool.self, forKey: .remindStreak) ?? d.remindStreak
        autoAdvance = try c.decodeIfPresent(Bool.self, forKey: .autoAdvance) ?? d.autoAdvance
        lineMode = try c.decodeIfPresent(Bool.self, forKey: .lineMode) ?? d.lineMode
        puckCount = try c.decodeIfPresent(Int.self, forKey: .puckCount) ?? d.puckCount
        sport = try c.decodeIfPresent(Sport.self, forKey: .sport) ?? d.sport
        trackGroup = try c.decodeIfPresent(TrackGroup.self, forKey: .trackGroup) ?? d.trackGroup
        normalOnEventDays = try c.decodeIfPresent(Bool.self, forKey: .normalOnEventDays) ?? d.normalOnEventDays
        adjustAfterEvents = try c.decodeIfPresent(Bool.self, forKey: .adjustAfterEvents) ?? d.adjustAfterEvents
        ignoreKeywords = try c.decodeIfPresent([String].self, forKey: .ignoreKeywords) ?? d.ignoreKeywords
        practiceKeywords = try c.decodeIfPresent([String].self, forKey: .practiceKeywords) ?? d.practiceKeywords
        hidePastEvents = try c.decodeIfPresent(Bool.self, forKey: .hidePastEvents) ?? d.hidePastEvents
        allDayIgnore = try c.decodeIfPresent(Bool.self, forKey: .allDayIgnore) ?? d.allDayIgnore
        showFuel = try c.decodeIfPresent(Bool.self, forKey: .showFuel) ?? d.showFuel
        showMealGenerator = try c.decodeIfPresent(Bool.self, forKey: .showMealGenerator) ?? d.showMealGenerator
        showReadiness = try c.decodeIfPresent(Bool.self, forKey: .showReadiness) ?? d.showReadiness
        showDailyGoals = try c.decodeIfPresent(Bool.self, forKey: .showDailyGoals) ?? d.showDailyGoals
        showFigures = try c.decodeIfPresent(Bool.self, forKey: .showFigures) ?? d.showFigures
        showTips = try c.decodeIfPresent(Bool.self, forKey: .showTips) ?? d.showTips
        showHockeyTools = try c.decodeIfPresent(Bool.self, forKey: .showHockeyTools) ?? d.showHockeyTools
        lineCount = try c.decodeIfPresent(Int.self, forKey: .lineCount) ?? d.lineCount
        measureModes = try c.decodeIfPresent([String: String].self, forKey: .measureModes) ?? d.measureModes
        trainTimes = try c.decodeIfPresent([String: Int].self, forKey: .trainTimes) ?? d.trainTimes
        runRemind = try c.decodeIfPresent(Bool.self, forKey: .runRemind) ?? d.runRemind
        runRemindDays = try c.decodeIfPresent(Set<Int>.self, forKey: .runRemindDays) ?? d.runRemindDays
        runMinute = try c.decodeIfPresent(Int.self, forKey: .runMinute) ?? d.runMinute
        remindWater = try c.decodeIfPresent(Bool.self, forKey: .remindWater) ?? d.remindWater
        shotGoal = try c.decodeIfPresent(Int.self, forKey: .shotGoal) ?? d.shotGoal
        stickGoal = try c.decodeIfPresent(Int.self, forKey: .stickGoal) ?? d.stickGoal
        waterGoal = try c.decodeIfPresent(Int.self, forKey: .waterGoal) ?? d.waterGoal
        runGoalKm = try c.decodeIfPresent(Double.self, forKey: .runGoalKm) ?? d.runGoalKm
        mustDos = try c.decodeIfPresent([WorkoutItem].self, forKey: .mustDos) ?? d.mustDos
        mustDosInPrograms = try c.decodeIfPresent(Bool.self, forKey: .mustDosInPrograms) ?? d.mustDosInPrograms
        units = try c.decodeIfPresent(Units.self, forKey: .units) ?? d.units
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg) ?? d.weightKg
        heightCm = try c.decodeIfPresent(Double.self, forKey: .heightCm) ?? d.heightCm
        age = try c.decodeIfPresent(Int.self, forKey: .age) ?? d.age
        sex = try c.decodeIfPresent(Sex.self, forKey: .sex) ?? d.sex
        nutritionGoal = try c.decodeIfPresent(NutritionGoal.self, forKey: .nutritionGoal) ?? d.nutritionGoal
        kcalOverride = try c.decodeIfPresent(Int.self, forKey: .kcalOverride) ?? d.kcalOverride
        proteinOverride = try c.decodeIfPresent(Int.self, forKey: .proteinOverride) ?? d.proteinOverride
    }
}

struct TodayState: Codable {
    var dateKey: String
    var seed: Int
    var focus: Focus?
    var duration: Int
    var workout: Workout
}

struct AppData: Codable {
    var settings = Settings()
    var factors: [String: Double] = [:]
    var sessions: [SessionRecord] = []
    var custom: [Workout] = []
    var favorites: Set<String> = []
    var benchmarks: [BenchmarkEntry] = []
    var today: TodayState?
    var dayOverrides: [String: DayType] = [:]
    var onboarded = false
    var events: [CalEvent] = []
    var eventKinds: [String: EventKind] = [:]
    var lastSync: Date?
    var daily: [String: DailyLog] = [:]
    var foods: [FoodEntry] = []
    var customFoods: [Food] = []
    var favoriteFoods: Set<String> = []
    var dayScale: [String: Double] = [:]
    var pantry: Set<String> = []
    var trackPRs: [TrackPR] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        settings = try c.decodeIfPresent(Settings.self, forKey: .settings) ?? Settings()
        factors = try c.decodeIfPresent([String: Double].self, forKey: .factors) ?? [:]
        sessions = try c.decodeIfPresent([SessionRecord].self, forKey: .sessions) ?? []
        custom = try c.decodeIfPresent([Workout].self, forKey: .custom) ?? []
        favorites = try c.decodeIfPresent(Set<String>.self, forKey: .favorites) ?? []
        benchmarks = try c.decodeIfPresent([BenchmarkEntry].self, forKey: .benchmarks) ?? []
        today = try? c.decodeIfPresent(TodayState.self, forKey: .today)
        dayOverrides = try c.decodeIfPresent([String: DayType].self, forKey: .dayOverrides) ?? [:]
        onboarded = try c.decodeIfPresent(Bool.self, forKey: .onboarded) ?? false
        events = try c.decodeIfPresent([CalEvent].self, forKey: .events) ?? []
        eventKinds = try c.decodeIfPresent([String: EventKind].self, forKey: .eventKinds) ?? [:]
        lastSync = try c.decodeIfPresent(Date.self, forKey: .lastSync)
        daily = try c.decodeIfPresent([String: DailyLog].self, forKey: .daily) ?? [:]
        foods = try c.decodeIfPresent([FoodEntry].self, forKey: .foods) ?? []
        customFoods = try c.decodeIfPresent([Food].self, forKey: .customFoods) ?? []
        favoriteFoods = try c.decodeIfPresent(Set<String>.self, forKey: .favoriteFoods) ?? []
        dayScale = try c.decodeIfPresent([String: Double].self, forKey: .dayScale) ?? [:]
        pantry = try c.decodeIfPresent(Set<String>.self, forKey: .pantry) ?? []
        trackPRs = try c.decodeIfPresent([TrackPR].self, forKey: .trackPRs) ?? []
    }
}

extension SessionRecord {
    var symbol: String { activity?.symbol ?? focus.symbol }
    var subtitleExtra: String? { distance.map { String(format: "%.1f km", $0) } }
}
