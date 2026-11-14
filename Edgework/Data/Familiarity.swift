import Foundation

/// How well-known each exercise is. This isn't difficulty: a pull-up is hard but everyone knows it.
/// 1 = everyone knows it (high knees, quad pulls, push-ups), 2 = most athletes know it, 3 = specialised or new to most people.
extension Library {
    static let basicIDs: Set<String> = [
        "warmup-jog", "butt-kickers", "butt-kicks", "knee-hugs", "walking-quad-pull", "frankenstein", "side-skips", "carioca", "backpedal",
        "high-knees", "jumping-jacks", "arm-circles", "leg-swings-front", "leg-swings-lateral", "lateral-shuffle-warm", "wrist-circles",
        "easy-run", "easy-jog", "mile-run", "distance-run", "long-run", "shuttle-run", "cooldown-jog", "strides", "sprints-200", "sprint-40",
        "line-sprints", "stair-runs", "backward-run", "run-in-place", "hill-jog", "hill-sprints",
        "standing-hamstring", "side-reach", "standing-groin", "quad-stretch", "toe-touch", "butterfly-stretch", "cross-body-shoulder",
        "tricep-stretch", "calf-stretch", "neck-rolls", "cobra", "childs-pose",
        "air-squat", "sumo-squat", "forward-lunge", "walking-lunge", "reverse-lunge", "lateral-lunge", "calf-raise", "db-squat",
        "glute-bridge", "wall-sit", "step-ups",
        "push-up", "knee-push-up", "incline-push-up", "wide-push-up", "pull-up", "chin-up", "db-curl", "hammer-curl", "lateral-raise",
        "front-raise", "db-bench", "db-press", "bench-dip", "farmer-carry", "wrist-curl", "superman",
        "plank", "side-plank", "crunch", "sit-up", "bicycle-crunch", "flutter-kicks", "leg-raise", "heel-touches", "scissor-kicks",
        "mountain-climbers", "russian-twist",
        "star-jumps", "squat-jump", "burpees", "jump-rope", "box-jump", "broad-jump", "tuck-jump", "frog-jumps", "crab-walk", "bear-crawl",
        "stickhandling-session", "figure-8", "wide-narrow", "wrist-shots", "snap-shots", "slap-shots", "backhands",
    ]

    static let commonIDs: Set<String> = [
        "a-skips", "b-skips", "c-skips", "power-skips", "spiderman-lunge", "heel-toe-walk", "lunge-reach", "hip-cradle", "walking-lunge-twist",
        "inchworm", "gate-openers", "band-pull-apart", "worlds-greatest",
        "repeats-400", "tempo-1k", "fartlek", "tempo-run", "flying-sprints", "jog-sprint", "progression-run", "mile-repeats",
        "hill-repeats", "hill-long-repeats", "hill-power-walk", "hill-backward-walk",
        "figure-4", "downward-dog", "spinal-twist", "doorway-chest", "pigeon", "deep-squat-hold", "hamstring-band-stretch", "cat-cow",
        "kneeling-hip-flexor", "couch-stretch", "frog-stretch", "foam-roll-legs", "foam-roll-back", "wrist-stretch",
        "curtsy-lunge", "donkey-kick", "fire-hydrant", "squat-pulse", "single-leg-bridge", "glute-kickback", "goblet-squat",
        "bulgarian-split-squat", "romanian-deadlift", "single-leg-rdl", "kb-swing", "back-squat", "trap-deadlift", "banded-lateral-walk",
        "single-leg-calf-raise", "jump-squat-hold",
        "decline-push-up", "diamond-push-up", "arnold-press", "overhead-extension", "skull-crusher", "chest-fly", "reverse-fly",
        "upright-row", "negative-pull-up", "inverted-row", "db-row", "face-pull", "pike-push-up", "band-row", "plyo-push-up",
        "renegade-row", "towel-wring", "wrist-rotation-db", "wrist-rotation-stick",
        "reverse-crunch", "toe-touch-crunch", "plank-jacks", "side-plank-dip", "sit-up-twist", "windshield-wipers", "dead-bug",
        "bird-dog", "hollow-hold", "hanging-knee-raise", "plank-shoulder-taps", "v-ups", "suitcase-carry",
        "squat-jacks", "shadow-boxing", "half-burpee", "inchworm-push-up", "med-ball-slam", "split-jump", "pogo-hops", "skater-bound",
        "lateral-hop", "lateral-shuffle", "sprint-starts", "t-drill", "pro-agility", "shift-sprints", "skater-hops", "sprawls",
        "slide-board", "hop-stick", "eyes-closed-balance",
        "bounding", "walking-knee-drive", "duck-walk", "wall-drive", "ankling", "block-starts", "three-point-start", "accel-30",
        "sprint-60", "tempo-100", "rep-200", "rep-300", "rep-800", "hurdle-walkover", "chest-pass", "overhead-back-toss",
        "baton-exchange", "depth-jump",
        "toe-drag", "one-hand", "heads-up", "quick-hands", "obstacle-weave", "catch-release", "one-timers", "saucer-pass",
        "butterfly-drops", "reaction-ball", "corner-targets", "walk-in-shot", "puck-circle", "rebound-shots", "backhand-lift",
    ]

    static func familiarity(_ id: String) -> Int {
        basicIDs.contains(id) ? 1 : (commonIDs.contains(id) ? 2 : 3)
    }
}

enum Knowledge: Int, CaseIterable, Identifiable {
    case basics = 1, common = 2, everything = 3
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .basics: "Well-known only"
        case .common: "Common"
        case .everything: "Everything"
        }
    }
    var detail: String {
        switch self {
        case .basics: "Only moves almost everyone knows: high knees, quad pulls, push-ups, planks, wrist shots."
        case .common: "Adds moves most athletes know: A-skips, goblet squats, dead bugs, one-timers."
        case .everything: "All 300 exercises, including specialised drills."
        }
    }
}

extension Settings {
    /// In your workouts: known well enough for your setting, or learned in Study.
    func isFamiliar(_ ex: Exercise) -> Bool {
        Library.familiarity(ex.id) <= knowledge || learned.contains(ex.id)
    }
}
