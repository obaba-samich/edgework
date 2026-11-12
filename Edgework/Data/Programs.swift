import Foundation

struct Program: Identifiable {
    struct Entry {
        let id: String
        let block: Block
        let sets: Int?
        let base: Int?
    }

    let id: String
    let title: String
    let subtitle: String
    let focus: Focus
    let entries: [Entry]
    var sport: Sport = .hockey

    func workout(rest: RestLength) -> Workout {
        let items: [WorkoutItem] = entries.compactMap { e in
            guard let ex = Library.byID[e.id] else { return nil }
            let isWork = e.block == .main || e.block == .finisher
            let r = isWork ? Int((Double(ex.category.defaultRest) * rest.multiplier).rounded()) : 5
            return WorkoutItem(exerciseID: ex.id, sets: e.sets ?? ex.sets, base: e.base ?? ex.base, rest: r, block: e.block)
        }
        return Workout(title: title, subtitle: subtitle, focus: focus, items: items)
    }

    var exerciseCount: Int { entries.count }
}

private func w(_ id: String, _ sets: Int? = nil, _ base: Int? = nil) -> Program.Entry { .init(id: id, block: .warmup, sets: sets, base: base) }
private func m(_ id: String, _ sets: Int? = nil, _ base: Int? = nil) -> Program.Entry { .init(id: id, block: .main, sets: sets, base: base) }
private func f(_ id: String, _ sets: Int? = nil, _ base: Int? = nil) -> Program.Entry { .init(id: id, block: .finisher, sets: sets, base: base) }
private func c(_ id: String, _ sets: Int? = nil, _ base: Int? = nil) -> Program.Entry { .init(id: id, block: .cooldown, sets: sets, base: base) }

enum Programs {
    static func forSport(_ sport: Sport) -> [Program] {
        sport == .track ? track : all
    }

    static let track: [Program] = [
        Program(id: "t-drills", title: "Sprint Drill Warm-up", subtitle: "The full drill series before any speed work.", focus: .trackSpeed, entries: [
            w("warmup-jog"), w("a-skips"), w("b-skips"), w("high-knees"), w("butt-kickers"), w("ankling"), w("carioca"),
            m("wall-drive", 2, 10), m("fast-leg", 2, 6), m("strides", 4, 100),
        ], sport: .track),
        Program(id: "t-accel", title: "Acceleration Day", subtitle: "Starts, pushes and the first 30 meters.", focus: .trackSpeed, entries: [
            w("warmup-jog"), w("a-skips"), w("high-knees"), w("leg-swings-front"),
            m("wall-drive"), m("three-point-start"), m("block-starts"), m("accel-30"), m("broad-jump", 3, 4), f("plank"), c("couch-stretch"), c("standing-hamstring"),
        ], sport: .track),
        Program(id: "t-maxv", title: "Max Velocity", subtitle: "Flying sprints and elastic power. Full rest.", focus: .trackSpeed, entries: [
            w("warmup-jog"), w("a-skips"), w("b-skips"), w("ankling"),
            m("flying-30"), m("sprint-60", 3, 60), m("bounding", 3, 30), c("quad-stretch"), c("standing-hamstring"),
        ], sport: .track),
        Program(id: "t-se", title: "Speed Endurance", subtitle: "Hold speed when it hurts: 150s and 200s.", focus: .speedEndurance, entries: [
            w("warmup-jog"), w("a-skips"), w("high-knees"), w("butt-kickers"),
            m("speed-150", 3, 150), m("rep-200", 2, 200), c("cooldown-jog"), c("standing-hamstring"), c("quad-stretch"),
        ], sport: .track),
        Program(id: "t-400", title: "400 Day", subtitle: "Lactate work for the one-lap race.", focus: .speedEndurance, entries: [
            w("warmup-jog"), w("a-skips"), w("carioca"),
            m("rep-300", 3, 300), m("tempo-100", 4, 100), c("cooldown-jog"), c("butterfly-stretch"),
        ], sport: .track),
        Program(id: "t-tempo", title: "Tempo Day", subtitle: "Smooth 100s. Recovery and aerobic base.", focus: .tempo, entries: [
            w("warmup-jog"), w("leg-swings-front"), w("leg-swings-lateral"),
            m("tempo-100", 10, 100), f("plank"), f("side-plank"), c("standing-hamstring"), c("calf-stretch"),
        ], sport: .track),
        Program(id: "t-hurdles", title: "Hurdle Technique", subtitle: "Mobility, lead and trail legs, rhythm.", focus: .hurdleDay, entries: [
            w("warmup-jog"), w("hurdle-walkover"), w("hurdle-mobility"), w("a-skips"),
            m("lead-leg"), m("trail-leg"), m("three-step"), m("hurdle-hops"), c("standing-groin"), c("figure-4"),
        ], sport: .track),
        Program(id: "t-jumps", title: "Jumps Power", subtitle: "Approach, takeoff and reactive plyos.", focus: .jumpDay, entries: [
            w("warmup-jog"), w("a-skips"), w("power-skips"), w("ankling"),
            m("approach-runs"), m("pop-ups"), m("single-leg-bound"), m("standing-triple"), m("depth-jump"), c("couch-stretch"), c("calf-stretch"),
        ], sport: .track),
        Program(id: "t-throws", title: "Throws Power", subtitle: "Med ball power and technique drills.", focus: .throwDay, entries: [
            w("jumping-jacks"), w("arm-circles"), w("worlds-greatest"),
            m("overhead-back-toss"), m("chest-pass"), m("rotational-scoop"), m("shot-stand"), m("discus-turn-drill"), m("kb-swing"), c("cross-body-shoulder"), c("open-book"),
        ], sport: .track),
        Program(id: "t-distance", title: "Distance Threshold", subtitle: "Tempo kilometers and strides.", focus: .distance, entries: [
            w("warmup-jog"), w("leg-swings-front"), w("a-skips"),
            m("tempo-1k", 3, 1000), m("strides", 4, 100), c("cooldown-jog"), c("calf-stretch"), c("standing-hamstring"),
        ], sport: .track),
        Program(id: "t-premeet", title: "Pre-Meet Activation", subtitle: "Wake up the legs the day before or morning of a meet.", focus: .activation, entries: [
            w("warmup-jog"), w("a-skips"), w("b-skips"), w("ankling"),
            m("wall-drive", 1, 10), m("accel-30", 2, 30), m("strides", 3, 100),
        ], sport: .track),
    ]

    static let all: [Program] = [
        Program(id: "pregame", title: "Pre-Game Activation", subtitle: "15 minutes before you get dressed. Fire up, don't fatigue.", focus: .activation, entries: [
            w("jumping-jacks"), w("leg-swings-front"), w("leg-swings-lateral"), w("gate-openers"), w("worlds-greatest", 1, 3),
            m("adductor-rockback", 1, 8), m("pogo-hops", 2, 15), m("squat-jump", 2, 4), m("skater-bound", 2, 4), m("quick-feet", 2, 10),
        ]),
        Program(id: "postgame", title: "Post-Game Flush", subtitle: "Light movement and long holds to bounce back for tomorrow.", focus: .recovery, entries: [
            w("arm-circles"), m("cat-cow"), m("hip-90-90"), m("couch-stretch"), m("frog-stretch"), m("pigeon"),
            m("open-book"), m("hamstring-band-stretch"), m("childs-pose", 1, 60),
        ]),
        Program(id: "stride", title: "Explosive Stride", subtitle: "Lateral power and single-leg strength for a faster first three strides.", focus: .power, entries: [
            w("jumping-jacks"), w("leg-swings-lateral"), w("lateral-shuffle-warm"), w("a-skips"),
            m("skater-bound"), m("broad-jump"), m("heiden-hold"), m("bulgarian-split-squat"), m("lateral-lunge"), m("single-leg-calf-raise"),
            f("lateral-bound-sprint"), c("couch-stretch"), c("frog-stretch"),
        ]),
        Program(id: "groin", title: "Groin Guard", subtitle: "Injury-proofing for the adductors and hips. Do it twice a week, all season.", focus: .strength, entries: [
            w("leg-swings-lateral"), w("gate-openers"), w("adductor-rockback"),
            m("copenhagen-plank"), m("lateral-lunge"), m("cossack-squat"), m("banded-lateral-walk"), m("nordic-curl"), m("side-plank"),
            c("frog-stretch"), c("hip-90-90"),
        ]),
        Program(id: "core", title: "Iron Core", subtitle: "Anti-rotation and bracing for a harder shot and staying on your feet.", focus: .core, entries: [
            w("inchworm"), w("worlds-greatest"),
            m("dead-bug"), m("pallof-press"), m("side-plank"), m("plank-shoulder-taps"), m("hollow-hold"), m("med-ball-rotation-throw"), m("suitcase-carry"),
            f("mountain-climbers"), c("childs-pose"), c("open-book"),
        ]),
        Program(id: "armor", title: "Upper Body Armor", subtitle: "Battle strength, healthy shoulders and a grip that won't quit.", focus: .strength, entries: [
            w("arm-circles"), w("band-pull-apart"), w("inchworm"),
            m("push-up"), m("pull-up"), m("db-row"), m("db-press"), m("face-pull"), m("farmer-carry"), m("wrist-curl"),
            c("open-book"), c("foam-roll-back"),
        ]),
        Program(id: "shift", title: "Shift Engine", subtitle: "Hockey-specific intervals. Short, hard, repeatable.", focus: .conditioning, entries: [
            w("jumping-jacks"), w("high-knees"), w("lateral-shuffle-warm"),
            m("shift-sprints", 6, 40), m("skater-hops"), m("burpees"), m("sprawls"),
            f("plank"), c("couch-stretch"), c("childs-pose"),
        ]),
        Program(id: "hands", title: "Hands of Gold", subtitle: "Off-ice stickhandling circuit. Eyes up, soft hands.", focus: .hands, entries: [
            w("arm-circles"), w("wrist-curl", 1, 15),
            m("quick-hands"), m("wide-narrow"), m("figure-8"), m("toe-drag"), m("one-hand"), m("heads-up"), m("obstacle-weave"), m("between-legs"),
        ]),
        Program(id: "sniper", title: "Sniper Session", subtitle: "100+ shots with purpose. Pick corners on every rep.", focus: .hands, entries: [
            w("arm-circles"), w("walking-lunge-twist"),
            m("wrist-shots", 4, 20), m("snap-shots", 4, 15), m("backhands", 3, 15), m("catch-release", 3, 15), m("slap-shots", 3, 10),
            f("med-ball-rotation-throw"),
        ]),
        Program(id: "edges", title: "Edge Control", subtitle: "Balance and single-leg control for sharper edges.", focus: .core, entries: [
            w("leg-swings-front"), w("leg-swings-lateral"), w("lateral-shuffle-warm"),
            m("star-reach"), m("hop-stick"), m("skater-squat"), m("single-leg-rdl"), m("eyes-closed-balance"), m("lateral-hop"), m("single-leg-squat-reach"),
            c("knee-to-wall"), c("pigeon"),
        ]),
        Program(id: "hotel", title: "Hotel Room", subtitle: "Road trip? Zero equipment, small space, full session.", focus: .fullBody, entries: [
            w("jumping-jacks"), w("high-knees"), w("worlds-greatest"),
            m("squat-jump"), m("reverse-lunge"), m("push-up"), m("glute-bridge"), m("skater-hops"), m("plank"), m("side-plank"),
            f("burpees"), c("pigeon"), c("childs-pose"),
        ]),
        Program(id: "goalie", title: "Goalie Flow", subtitle: "Hip mobility, lateral power and reactions.", focus: .goalie, entries: [
            w("leg-swings-lateral"), w("gate-openers"), w("worlds-greatest"),
            m("goalie-hip-rotation"), m("butterfly-drops"), m("t-push-shuffle"), m("goalie-shuffle-drop"), m("reaction-ball"), m("copenhagen-plank"), m("lateral-hop"),
            c("hip-ir-stretch"), c("frog-stretch"),
        ]),
        Program(id: "legday", title: "Heavy Legs", subtitle: "Off-season strength. Barbell required.", focus: .strength, entries: [
            w("jumping-jacks"), w("leg-swings-front"), w("worlds-greatest"), w("glute-bridge", 1, 12),
            m("box-jump", 3, 4), m("back-squat"), m("trap-deadlift"), m("bulgarian-split-squat"), m("nordic-curl"), m("copenhagen-plank"),
            c("couch-stretch"), c("hamstring-band-stretch"),
        ]),
    ]
}
