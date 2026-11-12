import SwiftUI

// MARK: - Daily tracking

enum ShotType: String, Codable, CaseIterable, Identifiable {
    case wrist, snap, slap, backhand, oneTimer
    var id: String { rawValue }
    var title: String {
        switch self {
        case .wrist: "Wrist"
        case .snap: "Snap"
        case .slap: "Slap"
        case .backhand: "Backhand"
        case .oneTimer: "One-timer"
        }
    }
    var color: Color {
        switch self {
        case .wrist: Color(hex: 0xB8F36B)
        case .snap: Color(hex: 0x7CD4FF)
        case .slap: Color(hex: 0xFF4D5E)
        case .backhand: Color(hex: 0xFFB547)
        case .oneTimer: Color(hex: 0x9B86FF)
        }
    }

    /// Shooting exercises that count toward the shot tracker when completed.
    static let exerciseMap: [String: ShotType] = [
        "wrist-shots": .wrist, "snap-shots": .snap, "slap-shots": .slap, "backhands": .backhand, "catch-release": .oneTimer,
    ]
}

struct DailyLog: Codable, Hashable {
    var shots: [String: Int] = [:]
    var onTarget = 0
    var stickMinutes = 0
    var runKm = 0.0
    var water = 0
    var sleep: Double?
    var soreness: Int?
    var energy: Int?
    var weightKg: Double?

    var totalShots: Int { shots.values.reduce(0, +) }
    func shots(_ t: ShotType) -> Int { shots[t.rawValue] ?? 0 }

    /// 0–100 from sleep, soreness and energy. Nil until checked in.
    var readiness: Int? {
        guard let sleep, let soreness, let energy else { return nil }
        let s = min(sleep / 8.5, 1) * 40
        let so = Double(5 - soreness) / 4 * 30
        let e = Double(energy - 1) / 4 * 30
        return Int((s + so + e).rounded())
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        shots = try c.decodeIfPresent([String: Int].self, forKey: .shots) ?? [:]
        onTarget = try c.decodeIfPresent(Int.self, forKey: .onTarget) ?? 0
        stickMinutes = try c.decodeIfPresent(Int.self, forKey: .stickMinutes) ?? 0
        runKm = try c.decodeIfPresent(Double.self, forKey: .runKm) ?? 0
        water = try c.decodeIfPresent(Int.self, forKey: .water) ?? 0
        sleep = try c.decodeIfPresent(Double.self, forKey: .sleep)
        soreness = try c.decodeIfPresent(Int.self, forKey: .soreness)
        energy = try c.decodeIfPresent(Int.self, forKey: .energy)
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg)
    }
}

// MARK: - Food

enum Meal: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack, preGame, postWorkout, drinks
    var id: String { rawValue }
    var title: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snacks"
        case .preGame: "Pre-game / Pre-workout"
        case .postWorkout: "Post-workout"
        case .drinks: "Drinks"
        }
    }
    var symbol: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "carrot.fill"
        case .preGame: "bolt.fill"
        case .postWorkout: "arrow.counterclockwise.circle.fill"
        case .drinks: "drop.fill"
        }
    }
    var color: Color {
        switch self {
        case .breakfast: Color(hex: 0xFFB547)
        case .lunch: Color(hex: 0xF5D76E)
        case .dinner: Color(hex: 0x9B86FF)
        case .snack: Color(hex: 0xFF8A5B)
        case .preGame: Color(hex: 0xFF4D5E)
        case .postWorkout: Color(hex: 0x3DDC97)
        case .drinks: Color(hex: 0x7CD4FF)
        }
    }

    /// Meal that fits the current time of day.
    static var now: Meal {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 4..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<17: return .snack
        case 17..<21: return .dinner
        default: return .snack
        }
    }
}

enum FoodBenefit: String, Codable, CaseIterable, Identifiable {
    case energy, recovery, hydration, bones, immunity, antiInflammatory, heart, gut, iron, sleep, brain
    var id: String { rawValue }
    var title: String {
        switch self {
        case .energy: "Energy"
        case .recovery: "Muscle recovery"
        case .hydration: "Hydration"
        case .bones: "Bones"
        case .immunity: "Immunity"
        case .antiInflammatory: "Anti-inflammatory"
        case .heart: "Heart"
        case .gut: "Gut & fiber"
        case .iron: "Iron"
        case .sleep: "Sleep"
        case .brain: "Focus"
        }
    }
    var symbol: String {
        switch self {
        case .energy: "bolt.fill"
        case .recovery: "arrow.counterclockwise"
        case .hydration: "drop.fill"
        case .bones: "figure.stand"
        case .immunity: "shield.fill"
        case .antiInflammatory: "flame.fill"
        case .heart: "heart.fill"
        case .gut: "leaf.fill"
        case .iron: "drop.triangle.fill"
        case .sleep: "moon.fill"
        case .brain: "brain.head.profile"
        }
    }
    var color: Color {
        switch self {
        case .energy: Color(hex: 0xFFB547)
        case .recovery: Color(hex: 0x3DDC97)
        case .hydration: Color(hex: 0x7CD4FF)
        case .bones: Color(hex: 0xE5E7EB)
        case .immunity: Color(hex: 0xB8F36B)
        case .antiInflammatory: Color(hex: 0xFF8A5B)
        case .heart: Color(hex: 0xFF4D5E)
        case .gut: Color(hex: 0x4FD1C5)
        case .iron: Color(hex: 0xC2410C)
        case .sleep: Color(hex: 0x9B86FF)
        case .brain: Color(hex: 0xF472B6)
        }
    }
    var detail: String {
        switch self {
        case .energy: "Carbohydrates fuel high-intensity skating. Top up before games and practices."
        case .recovery: "Protein repairs muscle. Aim for 20–40 g after training and spread it through the day."
        case .hydration: "Even small fluid losses slow you down. Drink before you're thirsty."
        case .bones: "Calcium and vitamin D keep bones strong for contact and falls."
        case .immunity: "Vitamin C, zinc and antioxidants help you stay healthy through a long season."
        case .antiInflammatory: "Omega-3s and antioxidants help manage soreness and inflammation."
        case .heart: "Healthy fats, potassium and fiber support your heart and blood pressure."
        case .gut: "Fiber and probiotics keep digestion steady (go lighter on fiber right before games)."
        case .iron: "Iron carries oxygen to muscles. Low iron means early fatigue."
        case .sleep: "Some foods support better sleep, which is when you actually recover."
        case .brain: "Steady energy and healthy fats help focus and reaction time."
        }
    }
}

enum FoodGroup: String, Codable, CaseIterable, Identifiable {
    case fruit, vegetable, grain, protein, dairy, fats, snack, meal, drink, sweet
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fruit: "Fruit"
        case .vegetable: "Vegetables"
        case .grain: "Grains & carbs"
        case .protein: "Protein"
        case .dairy: "Dairy"
        case .fats: "Nuts, seeds & fats"
        case .snack: "Snacks"
        case .meal: "Meals"
        case .drink: "Drinks"
        case .sweet: "Treats"
        }
    }
    var symbol: String {
        switch self {
        case .fruit: "leaf.circle.fill"
        case .vegetable: "carrot.fill"
        case .grain: "takeoutbag.and.cup.and.straw.fill"
        case .protein: "fish.fill"
        case .dairy: "cup.and.saucer.fill"
        case .fats: "circle.hexagongrid.fill"
        case .snack: "popcorn.fill"
        case .meal: "fork.knife"
        case .drink: "waterbottle.fill"
        case .sweet: "birthday.cake.fill"
        }
    }
}

struct Food: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var group: FoodGroup
    var serving: String
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double = 0
    var benefits: [FoodBenefit] = []
    var note: String = ""
    var source: String = "Edgework"
}

struct FoodEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var food: Food
    var servings: Double
    var meal: Meal
    var date: Date

    var kcal: Double { food.kcal * servings }
    var protein: Double { food.protein * servings }
    var carbs: Double { food.carbs * servings }
    var fat: Double { food.fat * servings }
}

// MARK: - Nutrition profile

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum NutritionGoal: String, Codable, CaseIterable, Identifiable {
    case lose, maintain, gain
    var id: String { rawValue }
    var title: String {
        switch self {
        case .lose: "Lean out"
        case .maintain: "Maintain"
        case .gain: "Build muscle"
        }
    }
    var kcalDelta: Double {
        switch self {
        case .lose: -400
        case .maintain: 0
        case .gain: 350
        }
    }
}

enum Units: String, Codable, CaseIterable, Identifiable {
    case imperial, metric
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct NutritionTargets {
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var water: Int
}
