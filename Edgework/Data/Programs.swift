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
