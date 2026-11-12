import SwiftUI

// MARK: - Exercise taxonomy

enum Category: String, Codable, CaseIterable, Identifiable {
    case warmup, lowerBody, upperBody, core, power, speed, conditioning, balance, mobility, stickhandling, shooting, goalie

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
    case reps, seconds, meters

    func label(_ value: Int) -> String {
        switch self {
        case .reps: return value == 1 ? "rep" : "reps"
        case .seconds: return "sec"
        case .meters: return "m"
        }
    }

    func format(_ value: Int) -> String {
        switch self {
        case .reps: return "\(value)"
        case .seconds: return value >= 60 && value % 60 == 0 ? "\(value / 60):00" : (value >= 60 ? String(format: "%d:%02d", value / 60, value % 60) : "\(value)s")
        case .meters: return "\(value)m"
        }
    }

    /// Rounds a scaled value to something you'd actually count.
    func round(_ raw: Double) -> Int {
        switch self {
        case .reps: return max(1, Int(raw.rounded()))
        case .seconds: return max(5, Int((raw / 5).rounded()) * 5)
        case .meters: return max(5, Int((raw / 5).rounded()) * 5)
        }
    }
}

enum Tag: String, Hashable {
    case cooldown, injuryPrevention, explosive, gameDay, noSpace
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
    case warmup, main, finisher, cooldown
    var id: String { rawValue }
    var title: String {
        switch self {
        case .warmup: "Warm-up"
        case .main: "Main Set"
        case .finisher: "Finisher"
        case .cooldown: "Cool-down"
        }
    }
}

enum Focus: String, Codable, CaseIterable, Identifiable {
    case activation, power, strength, speed, conditioning, core, hands, fullBody, goalie, mobility, recovery, custom

    var id: String { rawValue }

    static let generatable: [Focus] = [.power, .strength, .speed, .conditioning, .core, .hands, .fullBody, .goalie, .mobility, .recovery, .activation]

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

    var minutes: Int { max(1, Int((Double(duration) / 60).rounded())) }
    var totalSets: Int { entries.reduce(0) { $0 + $1.sets } }
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

struct Settings: Codable {
    var name = ""
    var position = Position.forward
    var phase = SeasonPhase.inseason
    var duration = 30
    var rest = RestLength.normal
    var intensity = 1.0
    var equipment: Set<Equipment> = Equipment.defaults
    var gameDays: Set<Int> = [7]
    var practiceDays: Set<Int> = [3, 5]
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
    }
}
