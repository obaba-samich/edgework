import Foundation

/// How well-known each exercise is, 1-9. This isn't difficulty: a pull-up is hard but everyone knows it.
/// Three sections of three: 1-3 the classics, 4-6 practice & gym moves, 7-9 specialised drills.
extension Library {
    /// Exercises at each level, index 0 = level 1.
    static let familiarityLevels: [[String]] = [
        // 1
        [
        "air-squat", "arm-circles", "burpees", "butt-kickers", "butt-kicks", "calf-raise", "cooldown-jog", "crunch", "db-curl",
        "distance-run", "easy-jog", "easy-run", "forward-lunge", "high-knees", "jump-rope", "jumping-jacks", "long-run", "mile-run",
        "mountain-climbers", "neck-rolls", "plank", "pull-up", "push-up", "quad-stretch", "run-in-place", "sit-up", "sprint-40",
        "standing-hamstring", "star-jumps", "stickhandling-session", "toe-touch", "wall-sit", "warmup-jog", "wrist-shots",
        ],
        // 2
        [
        "backhands", "backpedal", "bench-dip", "bicycle-crunch", "box-jump", "broad-jump", "butterfly-stretch", "calf-stretch",
        "childs-pose", "chin-up", "cobra", "cross-body-shoulder", "db-bench", "db-press", "flutter-kicks", "glute-bridge", "hammer-curl",
        "hill-jog", "hill-sprints", "incline-push-up", "knee-hugs", "knee-push-up", "lateral-lunge", "lateral-raise",
        "lateral-shuffle-warm", "leg-raise", "leg-swings-front", "leg-swings-lateral", "line-sprints", "reverse-lunge", "russian-twist",
        "shuttle-run", "side-plank", "side-reach", "side-skips", "slap-shots", "snap-shots", "squat-jump", "stair-runs", "standing-groin",
        "step-ups", "strides", "tricep-stretch", "walking-lunge", "walking-quad-pull", "wide-push-up", "wrist-circles",
        ],
        // 3
        [
        "backward-run", "bear-crawl", "carioca", "crab-walk", "db-squat", "farmer-carry", "figure-8", "frankenstein", "frog-jumps",
        "front-raise", "heel-touches", "scissor-kicks", "sprints-200", "sumo-squat", "superman", "tuck-jump", "wide-narrow", "wrist-curl",
        ],
        // 4
        [
        "a-skips", "arnold-press", "back-squat", "bird-dog", "block-starts", "bulgarian-split-squat", "cat-cow", "chest-fly",
        "curtsy-lunge", "db-row", "dead-bug", "decline-push-up", "diamond-push-up", "donkey-kick", "downward-dog", "fire-hydrant",
        "foam-roll-back", "foam-roll-legs", "goblet-squat", "half-burpee", "hanging-knee-raise", "hill-repeats", "inchworm", "kb-swing",
        "kneeling-hip-flexor", "med-ball-slam", "mile-repeats", "one-timers", "overhead-extension", "pigeon", "plank-jacks",
        "plank-shoulder-taps", "rep-200", "rep-800", "repeats-400", "reverse-crunch", "reverse-fly", "romanian-deadlift", "saucer-pass",
        "single-leg-calf-raise", "skull-crusher", "spinal-twist", "split-jump", "sprint-60", "sprint-starts", "squat-jacks", "tempo-run",
        "toe-drag", "trap-deadlift", "upright-row", "v-ups",
        ],
        // 5
        [
        "accel-30", "b-skips", "band-pull-apart", "band-row", "banded-lateral-walk", "baton-exchange", "bounding", "catch-release",
        "corner-targets", "couch-stretch", "deep-squat-hold", "doorway-chest", "face-pull", "fartlek", "figure-4", "frog-stretch",
        "gate-openers", "glute-kickback", "hamstring-band-stretch", "heads-up", "hill-power-walk", "hollow-hold", "inchworm-push-up",
        "inverted-row", "jog-sprint", "lateral-hop", "lateral-shuffle", "lunge-reach", "negative-pull-up", "one-hand", "pike-push-up",
        "plyo-push-up", "pogo-hops", "power-skips", "pro-agility", "progression-run", "quick-hands", "rebound-shots", "renegade-row",
        "rep-300", "shadow-boxing", "side-plank-dip", "single-leg-bridge", "single-leg-rdl", "sit-up-twist", "skater-bound", "skater-hops",
        "spiderman-lunge", "sprawls", "squat-pulse", "suitcase-carry", "t-drill", "tempo-1k", "three-point-start", "toe-touch-crunch",
        "walk-in-shot", "walking-lunge-twist", "windshield-wipers", "worlds-greatest",
        ],
        // 6
        [
        "ankling", "backhand-lift", "butterfly-drops", "c-skips", "chest-pass", "depth-jump", "duck-walk", "eyes-closed-balance",
        "flying-sprints", "heel-toe-walk", "hill-backward-walk", "hill-long-repeats", "hip-cradle", "hop-stick", "hurdle-walkover",
        "jump-squat-hold", "obstacle-weave", "overhead-back-toss", "puck-circle", "reaction-ball", "shift-sprints", "slide-board",
        "tempo-100", "towel-wring", "walking-knee-drive", "wall-drive", "wrist-rotation-db", "wrist-rotation-stick", "wrist-stretch",
        ],
        // 7
        [
        "backpedal-sprint", "between-legs", "copenhagen-plank", "cossack-squat", "crossover-run", "dangle-combo", "deke-backhand",
        "flying-30", "hip-90-90", "hurdle-hops", "knee-to-wall", "med-ball-rotation-throw", "nordic-curl", "open-book", "pallof-press",
        "puck-protection", "quick-feet", "shot-stand", "single-leg-bound", "single-leg-hip-thrust", "skater-squat", "speed-150",
        "speed-cones", "squat-thrust-tuck", "standing-triple", "toe-drag-shot",
        ],
        // 8
        [
        "adductor-rockback", "approach-runs", "around-puck-shot", "backhand-cradle", "box-bound", "eyes-closed-hands", "fast-leg",
        "figure8-one-hand", "goalie-shuffle-drop", "heiden-hold", "hill-bounds", "hill-lateral-shuffle", "hip-ir-stretch",
        "lateral-bound-sprint", "lead-leg", "low-glove-blocker", "middle-release", "pop-ups", "puck-maze", "quick-release-feet",
        "rotational-scoop", "single-leg-squat-reach", "skate-to-stick", "star-reach", "t-push-shuffle", "toe-drag-around", "trail-leg",
        ],
        // 9
        [
        "band-finger-extension", "discus-turn-drill", "goalie-hip-rotation", "hurdle-mobility", "javelin-crossovers", "scissor-kicks-hj",
        "stick-levers", "three-step",
        ],
    ]

    private static let familiarityByID: [String: Int] = {
        var d: [String: Int] = [:]
        for (i, ids) in familiarityLevels.enumerated() { for id in ids { d[id] = i + 1 } }
        return d
    }()

    /// 1-9. Anything not listed counts as the most specialised.
    static func familiarity(_ id: String) -> Int { familiarityByID[id] ?? 9 }
}

/// The three main sections of Exercises I know. Each has three levels.
enum KnowledgeSection: Int, CaseIterable, Identifiable {
    case classics = 1, practice = 2, specialised = 3
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .classics: "The classics"
        case .practice: "Practice & gym moves"
        case .specialised: "Specialised drills"
        }
    }
    var detail: String {
        switch self {
        case .classics: "Moves you'd know by name without looking them up."
        case .practice: "What you'd do at team practice or in a gym."
        case .specialised: "Drills you might need to look up first. Every one has steps and a demo."
        }
    }
    var levels: [Knowledge] { (1...3).compactMap { Knowledge(rawValue: (rawValue - 1) * 3 + $0) } }
}

/// One of the 9 Exercises I know levels. Each level includes everything below it.
enum Knowledge: Int, CaseIterable, Identifiable {
    case bareBasics = 1, everyday, allClassics, gymRegular, practiceRegular, allPractice, specialised, verySpecialised, everything
    var id: Int { rawValue }
    var section: KnowledgeSection { KnowledgeSection(rawValue: (rawValue - 1) / 3 + 1) ?? .specialised }
    /// 1-3 within its section.
    var step: Int { (rawValue - 1) % 3 + 1 }
    var title: String {
        switch self {
        case .bareBasics: "Bare basics"
        case .everyday: "Everyday moves"
        case .allClassics: "All the classics"
        case .gymRegular: "Gym basics"
        case .practiceRegular: "Practice regular"
        case .allPractice: "All practice & gym"
        case .specialised: "Some specialised"
        case .verySpecialised: "Most specialised"
        case .everything: "Everything"
        }
    }
    /// "Practice & gym moves · 2 of 3"
    var fullTitle: String { "\(section.title) · \(title)" }
    var detail: String {
        switch self {
        case .bareBasics: "Push-ups, squats, planks, jumping jacks, high knees, pull-ups."
        case .everyday: "Adds lunges, side planks, Russian twists, box jumps, tricep dips, slap shots."
        case .allClassics: "Adds bear crawls, carioca, sumo squats, farmer's carry, tuck jumps."
        case .gymRegular: "Adds goblet squats, deadlifts, dead bugs, A-skips, 400 m repeats, one-timers."
        case .practiceRegular: "Adds B-skips, World's Greatest Stretch, face pulls, pogo hops, the 5-10-5 shuttle."
        case .allPractice: "Adds C-skips, wall drives, depth jumps, slide board, wrist rotations."
        case .specialised: "Adds Nordic curls, Copenhagen planks, Pallof press, 90/90 hips, flying 30s."
        case .verySpecialised: "Adds hurdle lead and trail leg drills, Heiden jumps, puck mazes, pop-ups."
        case .everything: "Every move, including event drills like discus turns and javelin crossovers."
        }
    }
}

extension Settings {
    /// In your workouts: known well enough for your setting, or learned in Study.
    func isFamiliar(_ ex: Exercise) -> Bool {
        Library.familiarity(ex.id) <= knowledgeLevel || learned.contains(ex.id)
    }
}
