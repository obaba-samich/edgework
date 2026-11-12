import SwiftUI

// Animated demo figures. Each pose is a set of absolute limb angles
// (0° = pointing down, 90° = right, 180° = up). Joints come from forward
// kinematics, so bones keep their length while frames blend into each other.

struct Pose {
    var t: Double = 180          // hip → neck
    var h: Double?               // neck → head (defaults to torso)
    var aL: Double = 4, fL: Double = 8, aR: Double = -4, fR: Double = 4
    var lL: Double = 3, sL: Double = 0, lR: Double = -3, sR: Double = 0
    var lift: Double = 0
    var dx: Double = 0

    func w(_ change: (inout Pose) -> Void) -> Pose {
        var p = self
        change(&p)
        return p
    }

    /// Left/right swap, for alternating sides.
    var mirrored: Pose {
        var p = self
        p.t = -t; p.h = h.map { -$0 }
        p.aL = -aR; p.fL = -fR; p.aR = -aL; p.fR = -fL
        p.lL = -lR; p.sL = -sR; p.lR = -lL; p.sR = -sL
        p.dx = -dx
        return p
    }

    /// Side view: swap near/far limbs without flipping direction.
    var swapped: Pose {
        var p = self
        p.aL = aR; p.fL = fR; p.aR = aL; p.fR = fL
        p.lL = lR; p.sL = sR; p.lR = lL; p.sR = sL
        return p
    }

    static func lerp(_ a: Pose, _ b: Pose, _ u: Double) -> Pose {
        func ang(_ x: Double, _ y: Double) -> Double {
            var d = (y - x).truncatingRemainder(dividingBy: 360)
            if d > 180 { d -= 360 }
            if d < -180 { d += 360 }
            return x + d * u
        }
        func lin(_ x: Double, _ y: Double) -> Double { x + (y - x) * u }
        return Pose(t: ang(a.t, b.t), h: ang(a.h ?? a.t, b.h ?? b.t),
                    aL: ang(a.aL, b.aL), fL: ang(a.fL, b.fL), aR: ang(a.aR, b.aR), fR: ang(a.fR, b.fR),
                    lL: ang(a.lL, b.lL), sL: ang(a.sL, b.sL), lR: ang(a.lR, b.lR), sR: ang(a.sR, b.sR),
                    lift: lin(a.lift, b.lift), dx: lin(a.dx, b.dx))
    }
}

struct Move {
    enum Prop { case none, stick, bar, rope }
    var frames: [Pose]
    var duration: Double
    var front = false
    var prop = Prop.none
}

// MARK: - Base poses

private let S = Pose()                                                    // standing, side view
private let F = Pose(aL: -8, fL: -4, aR: 8, fR: 4, lL: -6, sL: -3, lR: 6, sR: 3) // standing, front view
private let squatLow = S.w { $0.t = 150; $0.aL = 95; $0.fL = 95; $0.aR = 92; $0.fR = 92; $0.lL = 82; $0.sL = -20; $0.lR = 78; $0.sR = -18 }
private let squatHigh = S.w { $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90 }
private let plankHigh = S.w { $0.t = 115; $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0; $0.lL = -65; $0.sL = -65; $0.lR = -64; $0.sR = -64 }
private let plankLow = plankHigh.w { $0.t = 98; $0.h = 95; $0.aL = -78; $0.fL = 58; $0.aR = -80; $0.fR = 60; $0.lL = -82; $0.sL = -82; $0.lR = -81; $0.sR = -81 }
private let forearmPlank = S.w { $0.t = 102.6; $0.aL = 2; $0.fL = 88; $0.aR = 0; $0.fR = 90; $0.lL = -77.4; $0.sL = -77.4; $0.lR = -77; $0.sR = -77 }
private let lie = S.w { $0.t = -90; $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90; $0.lL = 142; $0.sL = 28; $0.lR = 140; $0.sR = 30 }
private let lieFlat = lie.w { $0.lL = 92; $0.sL = 92; $0.lR = 90; $0.sR = 90 }
private let prone = S.w { $0.t = 90; $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90; $0.lL = -92; $0.sL = -92; $0.lR = -90; $0.sR = -90 }
private let quad = S.w { $0.t = 90; $0.aL = 47; $0.fL = 43; $0.aR = 45; $0.fR = 45; $0.lL = 2; $0.sL = -90; $0.lR = 0; $0.sR = -90 }
private let crouch = S.w { $0.t = 125; $0.aL = 12; $0.fL = 12; $0.aR = 10; $0.fR = 10; $0.lL = 102; $0.sL = -10; $0.lR = 100; $0.sR = -12 }
private let lungeLow = S.w { $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0; $0.lL = -15; $0.sL = -80; $0.lR = 80; $0.sR = 0 }
private let kneel = S.w { $0.lL = -12; $0.sL = -90; $0.lR = 80; $0.sR = 0 }
private let stanceF = F.w { $0.aL = -25; $0.fL = 25; $0.aR = 25; $0.fR = -25; $0.lL = -28; $0.sL = 6; $0.lR = 28; $0.sR = -6 }
private let hang = F.w { $0.aL = -168; $0.fL = -172; $0.aR = 168; $0.fR = 172; $0.lL = -3; $0.sL = -2; $0.lR = 3; $0.sR = 2; $0.lift = 6 }
private let seated = S.w { $0.t = 195; $0.aL = 60; $0.fL = 80; $0.aR = 58; $0.fR = 78; $0.lL = 118; $0.sL = 48; $0.lR = 116; $0.sR = 50 }
private let childBase = S.w { $0.t = 62; $0.h = 50; $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90; $0.lL = 72; $0.sL = -92; $0.lR = 70; $0.sR = -90 }
private let foldBase = S.w { $0.t = 22; $0.h = 12; $0.aL = 8; $0.fL = 8; $0.aR = 6; $0.fR = 6 }

private func hold(_ p: Pose, _ d: Double = 3.5, front: Bool = false) -> Move {
    Move(frames: [p, p.w { $0.t += 3; $0.h = ($0.h ?? $0.t) + 4 }], duration: d, front: front)
}

private func alternate(_ p: Pose, _ d: Double, front: Bool = false, prop: Move.Prop = .none) -> Move {
    Move(frames: [p, front ? p.mirrored : p.swapped], duration: d, front: front, prop: prop)
}

// MARK: - Library of moves

enum Moves {
    static let idle = hold(S, 3)
    static let squat = Move(frames: [squatHigh, squatLow], duration: 2.2)
    static let squatHold = hold(squatLow.w { $0.t = 165; $0.lL = 90; $0.sL = 0; $0.lR = 88; $0.sR = 0 })
    static let squatPulse = Move(frames: [squatLow, squatLow.w { $0.lL = 70; $0.lR = 66; $0.t = 158 }], duration: 0.6)
    static let deepSquat = hold(squatLow.w { $0.t = 165; $0.lL = 115; $0.sL = -25; $0.lR = 112; $0.sR = -25; $0.aL = 60; $0.fL = 120 })
    static let sumo = Move(frames: [F.w { $0.lL = -22; $0.sL = -18; $0.lR = 22; $0.sR = 18; $0.aL = 20; $0.fL = 120; $0.aR = -20; $0.fR = -120 },
                                    F.w { $0.lL = -62; $0.sL = -8; $0.lR = 62; $0.sR = 8; $0.aL = 20; $0.fL = 120; $0.aR = -20; $0.fR = -120 }],
                           duration: 2.2, front: true)
    static let lunge = Move(frames: [S, lungeLow], duration: 2.4)
    static let jumpLunge = Move(frames: [lungeLow, S.w { $0.lift = 10; $0.aL = 40; $0.aR = -30 }, lungeLow.swapped, S.w { $0.lift = 10; $0.aL = -30; $0.aR = 40 }], duration: 1.8)
    static let sideLunge: Move = {
        let low = F.w { $0.t = 178; $0.aL = 25; $0.fL = 100; $0.aR = -25; $0.fR = -100; $0.lL = -35; $0.sL = -35; $0.lR = 50; $0.sR = 0; $0.dx = 6 }
        return Move(frames: [F, low, F, low.mirrored], duration: 3.6, front: true)
    }()
    static let pushup = Move(frames: [plankHigh, plankLow], duration: 2.0)
    static let fastPushup = Move(frames: [plankHigh, plankLow, plankHigh.w { $0.lift = 4; $0.aL = 10; $0.aR = 8 }], duration: 1.2)
    static let kneePushup = Move(frames: [S.w { $0.t = 127; $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0; $0.lL = -53; $0.sL = -92; $0.lR = -53; $0.sR = -90 },
                                          S.w { $0.t = 101; $0.h = 97; $0.aL = -78; $0.fL = 58; $0.aR = -80; $0.fR = 60; $0.lL = -78; $0.sL = -92; $0.lR = -78; $0.sR = -90 }],
                                 duration: 2.0)
    static let pike = Move(frames: [S.w { $0.t = 60; $0.aL = 27; $0.fL = 27; $0.aR = 25; $0.fR = 25; $0.lL = -9; $0.sL = -9; $0.lR = -8; $0.sR = -8 },
                                    S.w { $0.t = 52; $0.h = 30; $0.aL = -28; $0.fL = 40; $0.aR = -30; $0.fR = 40; $0.lL = -9; $0.sL = -9; $0.lR = -8; $0.sR = -8 }],
                           duration: 2.2)
    static let downDog = hold(S.w { $0.t = 58; $0.h = 40; $0.aL = 50; $0.fL = 50; $0.aR = 48; $0.fR = 48; $0.lL = -30; $0.sL = -30; $0.lR = -28; $0.sR = -28 })
    static let plank = hold(forearmPlank)
    static let highPlank = hold(plankHigh)
    static let sidePlank = Move(frames: [forearmPlank.w { $0.aR = 178; $0.fR = 178 }, forearmPlank.w { $0.aR = 178; $0.fR = 178; $0.t = 98; $0.lL = -82; $0.sL = -82; $0.lR = -82; $0.sR = -82 }], duration: 2.6)
    static let shoulderTap = Move(frames: [plankHigh, plankHigh.w { $0.aR = 150; $0.fR = -60 }, plankHigh, plankHigh.w { $0.aL = 150; $0.fL = -60 }], duration: 1.6)
    static let mountainClimber = alternate(plankHigh.w { $0.lR = 60; $0.sR = -60 }, 0.55)
    static let jack = Move(frames: [F, F.w { $0.aL = -150; $0.fL = -162; $0.aR = 150; $0.fR = 162; $0.lL = -20; $0.sL = -20; $0.lR = 20; $0.sR = 20; $0.lift = 3 }], duration: 0.9, front: true)
    static let starJump = Move(frames: [F.w { $0.lL = -25; $0.sL = 10; $0.lR = 25; $0.sR = -10 }, F.w { $0.aL = -130; $0.fL = -130; $0.aR = 130; $0.fR = 130; $0.lL = -35; $0.sL = -35; $0.lR = 35; $0.sR = 35; $0.lift = 14 }], duration: 1.2, front: true)
    static let highKnees = alternate(S.w { $0.lR = 92; $0.sR = 0; $0.lL = 0; $0.aR = -35; $0.fR = 20; $0.aL = 35; $0.fL = 110; $0.lift = 2 }, 0.5)
    static let run = alternate(S.w { $0.t = 168; $0.lR = 60; $0.sR = 10; $0.lL = -25; $0.sL = -70; $0.aR = -40; $0.fR = 30; $0.aL = 40; $0.fL = 120; $0.lift = 4 }, 0.6)
    static let walk = alternate(S.w { $0.lR = 20; $0.sR = 5; $0.lL = -18; $0.sL = -25; $0.aR = -10; $0.fR = -6; $0.aL = 10; $0.fL = 14 }, 1.2)
    static let buttKick = alternate(S.w { $0.lR = -5; $0.sR = -165; $0.lL = 0; $0.sL = 0; $0.aR = 30; $0.fR = 100; $0.aL = -30; $0.fL = 20; $0.lift = 2 }, 0.5)
    static let burpee = Move(frames: [S, crouch, plankHigh, crouch, S.w { $0.aL = 172; $0.fL = 176; $0.aR = 176; $0.fR = 178; $0.lift = 10 }], duration: 3.4)
    static let halfBurpee = Move(frames: [S, crouch, plankHigh, crouch], duration: 2.6)
    static let inchworm = Move(frames: [S, foldBase, plankHigh, plankHigh, foldBase], duration: 4.4)
    static let crunch = Move(frames: [lie.w { $0.aL = -150; $0.fL = 70; $0.aR = -148; $0.fR = 72 }, lie.w { $0.t = -125; $0.aL = -185; $0.fL = 35; $0.aR = -183; $0.fR = 37 }], duration: 1.8)
    static let situp = Move(frames: [lie.w { $0.aL = 140; $0.fL = 120; $0.aR = 138; $0.fR = 118 }, lie.w { $0.t = -170; $0.aL = 60; $0.fL = 70; $0.aR = 58; $0.fR = 68 }], duration: 2.2)
    static let vup = Move(frames: [lieFlat.w { $0.aL = -92; $0.fL = -92; $0.aR = -90; $0.fR = -90; $0.lift = 0 }, lieFlat.w { $0.t = -140; $0.aL = 150; $0.fL = 150; $0.aR = 148; $0.fR = 148; $0.lL = 140; $0.sL = 140; $0.lR = 138; $0.sR = 138 }], duration: 2.0)
    static let hollow = hold(lieFlat.w { $0.t = -105; $0.aL = -100; $0.fL = -100; $0.aR = -98; $0.fR = -98; $0.lL = 105; $0.sL = 105; $0.lR = 103; $0.sR = 103 })
    static let legRaise = Move(frames: [lieFlat.w { $0.lL = 100; $0.sL = 100; $0.lR = 98; $0.sR = 98 }, lieFlat.w { $0.lL = 178; $0.sL = 178; $0.lR = 176; $0.sR = 176 }], duration: 2.2)
    static let flutter = alternate(lieFlat.w { $0.lR = 112; $0.sR = 112; $0.lL = 98; $0.sL = 98 }, 0.5)
    static let bicycle = alternate(lie.w { $0.t = -120; $0.aL = -170; $0.fL = 60; $0.aR = -168; $0.fR = 62; $0.lR = 150; $0.sR = 35; $0.lL = 100; $0.sL = 100 }, 1.0)
    static let bridge = Move(frames: [lie, lie.w { $0.t = -110; $0.lL = 102; $0.sL = -10; $0.lR = 100; $0.sR = -12 }], duration: 2.0)
    static let deadBug = alternate(lie.w { $0.aL = 178; $0.fL = 178; $0.aR = -125; $0.fR = -125; $0.lL = 180; $0.sL = 90; $0.lR = 98; $0.sR = 98 }, 2.0)
    static let twist = Move(frames: [seated.w { $0.aL = 50; $0.fL = 20; $0.aR = 48; $0.fR = 22 }, seated.w { $0.aL = 120; $0.fL = 150; $0.aR = 118; $0.fR = 148 }], duration: 1.2)
    static let superman = Move(frames: [prone, prone.w { $0.t = 76; $0.h = 70; $0.aL = 76; $0.fL = 76; $0.aR = 74; $0.fR = 74; $0.lL = -104; $0.sL = -104; $0.lR = -102; $0.sR = -102 }], duration: 2.0)
    static let cobra = hold(prone.w { $0.t = 62; $0.h = 50; $0.aL = 8; $0.fL = -6; $0.aR = 6; $0.fR = -8 })
    static let birdDog = Move(frames: [quad, quad.w { $0.aR = 90; $0.fR = 90; $0.lL = -90; $0.sL = -90 }], duration: 2.4)
    static let donkeyKick = Move(frames: [quad, quad.w { $0.lR = -150; $0.sR = 175 }], duration: 1.4)
    static let catCow = Move(frames: [quad.w { $0.t = 84; $0.h = 120 }, quad.w { $0.t = 96; $0.h = 40 }], duration: 3.0)
    static let rockBack = Move(frames: [quad, childBase], duration: 2.6)
    static let bearCrawl = alternate(S.w { $0.t = 80; $0.aL = 20; $0.fL = 20; $0.aR = 35; $0.fR = 35; $0.lL = 35; $0.sL = -30; $0.lR = 55; $0.sR = -10 }, 0.8)
    static let hinge = Move(frames: [S.w { $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0 }, S.w { $0.t = 100; $0.h = 105; $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0; $0.lL = 12; $0.sL = 0; $0.lR = 10; $0.sR = 0 }], duration: 2.4)
    static let swing = Move(frames: [S.w { $0.t = 115; $0.aL = -15; $0.fL = -15; $0.aR = -13; $0.fR = -13; $0.lL = 25; $0.sL = -5; $0.lR = 23; $0.sR = -5 }, S.w { $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90 }], duration: 1.2)
    static let nordic = Move(frames: [kneel.w { $0.lR = -12; $0.sR = -90; $0.aL = 2; $0.aR = 0 }, kneel.w { $0.t = 108; $0.lR = -12; $0.sR = -90; $0.aL = 70; $0.fL = 70; $0.aR = 68; $0.fR = 68 }], duration: 3.0)
    static let press = Move(frames: [F.w { $0.aL = -100; $0.fL = 178; $0.aR = 100; $0.fR = -178 }, F.w { $0.aL = -172; $0.fL = -176; $0.aR = 172; $0.fR = 176 }], duration: 2.0, front: true)
    static let benchPress = Move(frames: [lie.w { $0.aL = 178; $0.fL = 178; $0.aR = 176; $0.fR = 176 }, lie.w { $0.aL = 100; $0.fL = 178; $0.aR = 98; $0.fR = 176 }], duration: 2.0)
    static let curl = Move(frames: [S.w { $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0 }, S.w { $0.aL = 6; $0.fL = 160; $0.aR = 4; $0.fR = 158 }], duration: 1.8)
    static let tricepExt = Move(frames: [S.w { $0.aL = 172; $0.fL = 176; $0.aR = 170; $0.fR = 174 }, S.w { $0.aL = 172; $0.fL = 20; $0.aR = 170; $0.fR = 18 }], duration: 2.0)
    static let row = Move(frames: [S.w { $0.t = 125; $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0; $0.lL = 18; $0.sL = -6; $0.lR = 16; $0.sR = -6 },
                                   S.w { $0.t = 125; $0.aL = -58; $0.fL = 4; $0.aR = -60; $0.fR = 2; $0.lL = 18; $0.sL = -6; $0.lR = 16; $0.sR = -6 }], duration: 1.8)
    static let standRow = Move(frames: [S.w { $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90 }, S.w { $0.aL = -30; $0.fL = 100; $0.aR = -32; $0.fR = 98 }], duration: 1.8)
    static let bandPress = Move(frames: [S.w { $0.aL = 30; $0.fL = 120; $0.aR = 28; $0.fR = 118 }, S.w { $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90 }], duration: 2.2)
    static let lateralRaise = Move(frames: [F, F.w { $0.aL = -88; $0.fL = -95; $0.aR = 88; $0.fR = 95 }], duration: 2.0, front: true)
    static let frontRaise = Move(frames: [S.w { $0.aL = 2; $0.fL = 2; $0.aR = 0; $0.fR = 0 }, S.w { $0.aL = 92; $0.fL = 95; $0.aR = 90; $0.fR = 93 }], duration: 2.0)
    static let armCircle = Move(frames: [F.w { $0.aL = -80; $0.fL = -80; $0.aR = 80; $0.fR = 80 }, F.w { $0.aL = -95; $0.fL = -100; $0.aR = 95; $0.fR = 100 },
                                         F.w { $0.aL = -100; $0.fL = -95; $0.aR = 100; $0.fR = 95 }, F.w { $0.aL = -85; $0.fL = -78; $0.aR = 85; $0.fR = 78 }], duration: 1.0, front: true)
    static let dip = Move(frames: [S.w { $0.aL = -22; $0.fL = 0; $0.aR = -20; $0.fR = 0; $0.lL = 82; $0.sL = 2; $0.lR = 80; $0.sR = 0 },
                                   S.w { $0.t = 176; $0.aL = -82; $0.fL = 6; $0.aR = -80; $0.fR = 4; $0.lL = 72; $0.sL = 12; $0.lR = 70; $0.sR = 10 }], duration: 2.0)
    static let pullup = Move(frames: [hang, hang.w { $0.aL = -125; $0.fL = 175; $0.aR = 125; $0.fR = -175; $0.lift = 26 }], duration: 2.2, front: true, prop: .bar)
    static let hangingRaise = Move(frames: [hang, hang.w { $0.lL = 115; $0.sL = 5; $0.lR = 113; $0.sR = 3; $0.lift = 26 }], duration: 2.0, front: true, prop: .bar)
    static let jumpSquat = Move(frames: [squatLow.w { $0.aL = -40; $0.fL = -40; $0.aR = -42; $0.fR = -42 }, S.w { $0.aL = 170; $0.fL = 175; $0.aR = 168; $0.fR = 173; $0.lift = 16 }], duration: 1.3)
    static let tuckJump = Move(frames: [squatHigh.w { $0.t = 170; $0.lL = 30; $0.sL = -25; $0.lR = 28; $0.sR = -25 }, S.w { $0.lL = 120; $0.sL = 0; $0.lR = 118; $0.sR = 0; $0.aL = 100; $0.fL = 100; $0.aR = 98; $0.fR = 98; $0.lift = 18 }], duration: 1.0)
    static let broadJump = Move(frames: [squatLow.w { $0.aL = -50; $0.fL = -50; $0.aR = -52; $0.fR = -52; $0.dx = -12 }, S.w { $0.t = 150; $0.aL = 120; $0.fL = 130; $0.aR = 118; $0.fR = 128; $0.lL = 40; $0.sL = 10; $0.lR = 38; $0.sR = 8; $0.lift = 14 }, squatLow.w { $0.dx = 12 }], duration: 1.8)
    static let pogo = Move(frames: [F, F.w { $0.lift = 6 }], duration: 0.45, front: true)
    static let jumpRope = Move(frames: [F.w { $0.aL = -25; $0.fL = 30; $0.aR = 25; $0.fR = -30 }, F.w { $0.aL = -25; $0.fL = 30; $0.aR = 25; $0.fR = -30; $0.lift = 6 }], duration: 0.5, front: true, prop: .rope)
    static let calfRaise = Move(frames: [S, S.w { $0.lift = 4 }], duration: 1.4)
    static let skater: Move = {
        let land = F.w { $0.t = 170; $0.aL = 50; $0.fL = 70; $0.aR = -30; $0.fR = -40; $0.lL = 30; $0.sL = 75; $0.lR = 28; $0.sR = -6; $0.dx = -16 }
        let air = F.w { $0.lift = 8; $0.lL = -14; $0.sL = -6; $0.lR = 14; $0.sR = 6 }
        return Move(frames: [land, air, land.mirrored, air], duration: 1.8, front: true)
    }()
    static let shuffle = Move(frames: [stanceF.w { $0.dx = -10 }, stanceF.w { $0.lL = -18; $0.lR = 18; $0.lift = 2 }, stanceF.w { $0.dx = 10 }, stanceF.w { $0.lL = -18; $0.lR = 18; $0.lift = 2 }], duration: 1.4, front: true)
    static let slam = Move(frames: [S.w { $0.t = 185; $0.aL = 175; $0.fL = 175; $0.aR = 173; $0.fR = 173; $0.lift = 2 }, S.w { $0.t = 110; $0.aL = 40; $0.fL = 30; $0.aR = 38; $0.fR = 28; $0.lL = 30; $0.sL = -10; $0.lR = 28; $0.sR = -10 }], duration: 1.2)
    static let legSwing = Move(frames: [S.w { $0.aL = 80; $0.fL = 80; $0.lR = 70; $0.sR = 60 }, S.w { $0.aL = 80; $0.fL = 80; $0.lR = -40; $0.sR = -40 }], duration: 1.3)
    static let balance = Move(frames: [F.w { $0.aL = -85; $0.fL = -88; $0.aR = 85; $0.fR = 88; $0.lR = 12; $0.sR = -45 }, F.w { $0.t = 176; $0.aL = -80; $0.fL = -84; $0.aR = 90; $0.fR = 92; $0.lR = 14; $0.sR = -40 }], duration: 2.4, front: true)
    static let starReach = Move(frames: [S.w { $0.t = 165; $0.aL = 80; $0.fL = 80; $0.aR = 78; $0.fR = 78; $0.lL = 15; $0.sL = -10; $0.lR = 75; $0.sR = 72 }, S.w { $0.t = 150; $0.aL = 85; $0.fL = 85; $0.aR = 83; $0.fR = 83; $0.lL = 20; $0.sL = -15; $0.lR = -60; $0.sR = -62 }], duration: 2.6)
    static let quadStretch = hold(S.w { $0.aL = 80; $0.fL = 80; $0.aR = -25; $0.fR = -15; $0.lR = -12; $0.sR = 178 })
    static let fold = hold(foldBase)
    static let kneelStretch = Move(frames: [lungeLow.w { $0.aR = 172; $0.fR = 172; $0.aL = 2; $0.fL = 2 }, lungeLow.w { $0.t = 188; $0.aR = 178; $0.fR = 182; $0.aL = 2; $0.fL = 2; $0.lR = 70; $0.sR = 5 }], duration: 3.5)
    static let childPose = hold(childBase)
    static let seatedStretch = Move(frames: [S.w { $0.t = 180; $0.aL = 30; $0.fL = 20; $0.aR = 28; $0.fR = 18; $0.lL = 78; $0.sL = -120; $0.lR = 76; $0.sR = -118 },
                                             S.w { $0.t = 158; $0.aL = 40; $0.fL = 30; $0.aR = 38; $0.fR = 28; $0.lL = 78; $0.sL = -120; $0.lR = 76; $0.sR = -118 }], duration: 3.5)
    static let lyingStretch = hold(lieFlat.w { $0.aR = 160; $0.fR = 168; $0.lR = 172; $0.sR = 172 })
    static let armStretch = hold(F.w { $0.aR = -70; $0.fR = -85; $0.aL = 30; $0.fL = -70 }, front: true)
    static let tricepStretch = hold(F.w { $0.aR = 172; $0.fR = 15; $0.aL = 150; $0.fL = 100 }, front: true)
    static let calfStretch = hold(S.w { $0.t = 150; $0.aL = 100; $0.fL = 100; $0.aR = 98; $0.fR = 98; $0.lL = -30; $0.sL = -30; $0.lR = 25; $0.sR = 10 })
    static let box = Move(frames: [S.w { $0.aL = 50; $0.fL = 155; $0.aR = 48; $0.fR = 152; $0.lL = 15; $0.lR = -12 }, S.w { $0.aL = 90; $0.fL = 90; $0.aR = 48; $0.fR = 152; $0.lL = 15; $0.lR = -12 },
                                   S.w { $0.aL = 50; $0.fL = 155; $0.aR = 48; $0.fR = 152; $0.lL = 15; $0.lR = -12 }, S.w { $0.t = 170; $0.aL = 50; $0.fL = 155; $0.aR = 92; $0.fR = 90; $0.lL = 15; $0.lR = -12 }], duration: 1.4)
    static let stickhandle = Move(frames: [stanceF.w { $0.t = 172; $0.aL = 20; $0.fL = 60; $0.aR = 5; $0.fR = 40 }, stanceF.w { $0.t = 188; $0.aL = -40; $0.fL = -5; $0.aR = -30; $0.fR = -40 }], duration: 0.7, front: true, prop: .stick)
    static let shoot = Move(frames: [S.w { $0.t = 172; $0.aL = -100; $0.fL = -60; $0.aR = -60; $0.fR = -30; $0.lL = 20; $0.sL = 0; $0.lR = -15; $0.sR = 0 },
                                     S.w { $0.t = 165; $0.aL = 30; $0.fL = 80; $0.aR = 20; $0.fR = 50; $0.lL = 25; $0.sL = 0; $0.lR = -20; $0.sR = 0 },
                                     S.w { $0.t = 160; $0.aL = 110; $0.fL = 140; $0.aR = 90; $0.fR = 110; $0.lL = 28; $0.sL = 0; $0.lR = -25; $0.sR = -30 }], duration: 1.4, prop: .stick)
    static let throwSide = Move(frames: [S.w { $0.t = 172; $0.aL = -70; $0.fL = -60; $0.aR = -60; $0.fR = -50; $0.lL = 20; $0.lR = -15 }, S.w { $0.t = 168; $0.aL = 100; $0.fL = 110; $0.aR = 90; $0.fR = 100; $0.lL = 22; $0.lR = -20 }], duration: 1.1)
    static let butterfly = Move(frames: [stanceF.w { $0.aL = -40; $0.fL = 20; $0.aR = 40; $0.fR = -20 }, F.w { $0.aL = -40; $0.fL = 20; $0.aR = 40; $0.fR = -20; $0.lL = 22; $0.sL = -88; $0.lR = -22; $0.sR = 88 }], duration: 1.6, front: true)
    static let catchBall = Move(frames: [stanceF.w { $0.aR = 140; $0.fR = 160 }, stanceF.w { $0.aL = -140; $0.fL = -160 }], duration: 1.0, front: true)
    static let kneeHug = alternate(S.w { $0.aL = 60; $0.fL = 150; $0.aR = 50; $0.fR = 140; $0.lR = 155; $0.sR = 10; $0.lift = 3 }, 1.6)
    static let frankenstein = alternate(S.w { $0.aL = 92; $0.fL = 92; $0.aR = 90; $0.fR = 90; $0.lR = 88; $0.sR = 88 }, 1.4)
    static let powerSkip = alternate(S.w { $0.lR = 100; $0.sR = 0; $0.aL = 160; $0.fL = 170; $0.aR = -30; $0.fR = 10; $0.lift = 12 }, 1.0)
    static let sideReach = hold(F.w { $0.t = 172; $0.aL = -170; $0.fL = 160; $0.aR = 30; $0.fR = 20 }, front: true)
    static let groin = hold(F.w { $0.lL = -50; $0.sL = -50; $0.lR = 45; $0.sR = 0; $0.aL = 25; $0.fL = 30; $0.aR = -10; $0.fR = -5; $0.dx = 6 }, front: true)
    static let figure4 = hold(S.w { $0.t = 160; $0.aL = 95; $0.fL = 95; $0.aR = 93; $0.fR = 93; $0.lL = 60; $0.sL = -15; $0.lR = 85; $0.sR = 80 })
    static let rollOut = Move(frames: [forearmPlank.w { $0.dx = -6 }, forearmPlank.w { $0.dx = 6 }], duration: 2.0)

    // MARK: Lookup

    static func move(for ex: Exercise) -> Move {
        if let m = byID[ex.id] { return m }
        switch ex.category {
        case .warmup: return jack
        case .lowerBody: return squat
        case .upperBody: return pushup
        case .core: return plank
        case .power: return jumpSquat
        case .speed: return run
        case .conditioning: return burpee
        case .balance: return balance
        case .mobility: return fold
        case .stickhandling: return stickhandle
        case .shooting: return shoot
        case .goalie: return shuffle
        case .running, .sprints: return run
        case .hurdles: return highKnees
        case .jumps: return broadJump
        case .throwing: return throwSide
        }
    }

    private static let byID: [String: Move] = [
        "jumping-jacks": jack, "high-knees": highKnees, "leg-swings-front": legSwing, "leg-swings-lateral": legSwing,
        "walking-lunge-twist": lunge, "worlds-greatest": kneelStretch, "arm-circles": armCircle, "inchworm": inchworm,
        "lateral-shuffle-warm": shuffle, "gate-openers": balance, "band-pull-apart": standRow, "a-skips": highKnees,
        "goblet-squat": squat, "bulgarian-split-squat": lunge, "reverse-lunge": lunge, "lateral-lunge": sideLunge,
        "cossack-squat": sideLunge, "single-leg-rdl": hinge, "romanian-deadlift": hinge, "glute-bridge": bridge,
        "single-leg-hip-thrust": bridge, "wall-sit": squatHold, "step-ups": lunge, "nordic-curl": nordic,
        "copenhagen-plank": sidePlank, "skater-squat": lunge, "single-leg-calf-raise": calfRaise, "kb-swing": swing,
        "back-squat": squat, "trap-deadlift": hinge, "banded-lateral-walk": shuffle,
        "push-up": pushup, "pull-up": pullup, "inverted-row": standRow, "db-bench": benchPress, "db-row": row,
        "db-press": press, "face-pull": standRow, "bench-dip": dip, "farmer-carry": walk, "wrist-curl": curl,
        "pike-push-up": pike, "renegade-row": shoulderTap, "band-row": standRow, "plyo-push-up": fastPushup,
        "plank": plank, "side-plank": sidePlank, "dead-bug": deadBug, "pallof-press": bandPress, "russian-twist": twist,
        "hollow-hold": hollow, "bird-dog": birdDog, "mountain-climbers": mountainClimber, "hanging-knee-raise": hangingRaise,
        "plank-shoulder-taps": shoulderTap, "v-ups": vup, "suitcase-carry": walk, "bear-crawl": bearCrawl,
        "med-ball-rotation-throw": throwSide,
        "box-jump": jumpSquat, "squat-jump": jumpSquat, "broad-jump": broadJump, "skater-bound": skater, "tuck-jump": tuckJump,
        "lateral-hop": pogo, "med-ball-slam": slam, "split-jump": jumpLunge, "pogo-hops": pogo, "heiden-hold": skater,
        "lateral-shuffle": shuffle, "crossover-run": run, "sprint-starts": run, "t-drill": run, "pro-agility": shuffle,
        "backpedal-sprint": run, "quick-feet": pogo, "lateral-bound-sprint": skater,
        "burpees": burpee, "shift-sprints": run, "skater-hops": skater, "jump-rope": jumpRope, "sprawls": halfBurpee,
        "slide-board": skater, "tempo-run": run, "squat-thrust-tuck": burpee,
        "star-reach": starReach, "hop-stick": broadJump, "eyes-closed-balance": balance, "single-leg-squat-reach": starReach,
        "hip-90-90": seatedStretch, "couch-stretch": kneelStretch, "frog-stretch": childPose, "pigeon": childPose,
        "open-book": lyingStretch, "deep-squat-hold": deepSquat, "hamstring-band-stretch": lyingStretch, "cat-cow": catCow,
        "adductor-rockback": rockBack, "kneeling-hip-flexor": kneelStretch, "childs-pose": childPose, "foam-roll-legs": rollOut,
        "foam-roll-back": bridge, "knee-to-wall": kneelStretch, "hip-ir-stretch": lyingStretch,
        "butterfly-drops": butterfly, "t-push-shuffle": shuffle, "reaction-ball": catchBall, "goalie-hip-rotation": seatedStretch,
        "goalie-shuffle-drop": butterfly,
        "air-squat": squat, "sumo-squat": sumo, "forward-lunge": lunge, "walking-lunge": lunge, "curtsy-lunge": lunge,
        "donkey-kick": donkeyKick, "fire-hydrant": donkeyKick, "calf-raise": calfRaise, "squat-pulse": squatPulse,
        "single-leg-bridge": bridge, "db-squat": squat, "glute-kickback": legSwing,
        "knee-push-up": kneePushup, "incline-push-up": pushup, "decline-push-up": pushup, "wide-push-up": pushup,
        "diamond-push-up": pushup, "chin-up": pullup, "db-curl": curl, "hammer-curl": curl, "lateral-raise": lateralRaise,
        "front-raise": frontRaise, "arnold-press": press, "overhead-extension": tricepExt, "skull-crusher": benchPress,
        "chest-fly": benchPress, "reverse-fly": row, "upright-row": lateralRaise, "superman": superman, "negative-pull-up": pullup,
        "crunch": crunch, "sit-up": situp, "bicycle-crunch": bicycle, "flutter-kicks": flutter, "leg-raise": legRaise,
        "reverse-crunch": legRaise, "heel-touches": crunch, "toe-touch-crunch": vup, "plank-jacks": mountainClimber,
        "side-plank-dip": sidePlank, "windshield-wipers": legRaise, "scissor-kicks": flutter, "sit-up-twist": situp,
        "butt-kicks": buttKick, "star-jumps": starJump, "squat-jacks": sumo, "shadow-boxing": box, "frog-jumps": broadJump,
        "run-in-place": run, "half-burpee": halfBurpee, "inchworm-push-up": inchworm, "jump-squat-hold": jumpSquat,
        "quad-stretch": quadStretch, "toe-touch": fold, "cobra": cobra, "butterfly-stretch": seatedStretch,
        "doorway-chest": armStretch, "cross-body-shoulder": armStretch, "tricep-stretch": tricepStretch,
        "downward-dog": downDog, "spinal-twist": lyingStretch, "calf-stretch": calfStretch, "neck-rolls": idle,
        "warmup-jog": run, "butt-kickers": buttKick, "knee-hugs": kneeHug, "walking-quad-pull": quadStretch,
        "frankenstein": frankenstein, "carioca": shuffle, "backpedal": run, "spiderman-lunge": kneelStretch,
        "power-skips": powerSkip, "b-skips": highKnees, "side-skips": jack, "hip-cradle": kneeHug, "heel-toe-walk": walk,
        "lunge-reach": kneelStretch, "easy-run": run, "strides": run, "sprints-200": run, "repeats-400": run,
        "hill-sprints": run, "tempo-1k": run, "mile-run": run, "fartlek": run, "shuttle-run": shuffle, "cooldown-jog": walk,
        "standing-hamstring": fold, "wall-drive": highKnees, "ankling": pogo, "fast-leg": highKnees, "hurdle-walkover": legSwing, "hurdle-mobility": legSwing, "lead-leg": legSwing, "trail-leg": legSwing, "hurdle-hops": tuckJump, "depth-jump": jumpSquat, "overhead-back-toss": slam, "chest-pass": bandPress, "box-bound": skater, "single-leg-bound": powerSkip, "approach-runs": run, "pop-ups": powerSkip, "scissor-kicks-hj": powerSkip, "baton-exchange": run, "javelin-crossovers": shuffle, "discus-turn-drill": throwSide, "stair-runs": highKnees, "bounding": powerSkip, "crab-walk": bearCrawl, "duck-walk": squatPulse, "walking-knee-drive": kneeHug, "distance-run": run, "stickhandling-session": stickhandle, "side-reach": sideReach, "standing-groin": groin, "figure-4": figure4,
    ]
}

// MARK: - View

struct FigureView: View {
    let move: Move
    var color: Color = Theme.ice
    var animate = true

    init(exercise: Exercise, color: Color? = nil, animate: Bool = true) {
        move = Moves.move(for: exercise)
        self.color = color ?? exercise.category.color
        self.animate = animate
    }

    var body: some View {
        TimelineView(.animation(paused: !animate)) { tl in
            Canvas { ctx, size in
                draw(ctx: ctx, size: size, time: tl.date.timeIntervalSinceReferenceDate)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private struct Joints {
        var hip, neck, head, eL, hL, eR, hR, kL, fL, kR, fR: CGPoint

        mutating func shift(_ dx: CGFloat, _ dy: CGFloat) {
            for kp in [\Joints.hip, \.neck, \.head, \.eL, \.hL, \.eR, \.hR, \.kL, \.fL, \.kR, \.fR] as [WritableKeyPath<Joints, CGPoint>] {
                self[keyPath: kp].x += dx
                self[keyPath: kp].y += dy
            }
        }
    }

    private func pose(at time: Double) -> Pose {
        let frames = move.frames
        guard frames.count > 1 else { return frames.first ?? Pose() }
        let p = (time / move.duration).truncatingRemainder(dividingBy: 1) * Double(frames.count)
        let i = Int(p) % frames.count
        var u = p - floor(p)
        u = u * u * (3 - 2 * u)
        return Pose.lerp(frames[i], frames[(i + 1) % frames.count], u)
    }

    private func joints(_ p: Pose) -> Joints {
        func dir(_ a: Double, _ len: CGFloat) -> CGPoint {
            let r = a * .pi / 180
            return CGPoint(x: CGFloat(sin(r)) * len, y: CGFloat(cos(r)) * len)
        }
        func add(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
        let hip = CGPoint.zero
        let neck = add(hip, dir(p.t, 26))
        let head = add(neck, dir(p.h ?? p.t, 9))
        let eL = add(neck, dir(p.aL, 14)), hL = add(eL, dir(p.fL, 13))
        let eR = add(neck, dir(p.aR, 14)), hR = add(eR, dir(p.fR, 13))
        let kL = add(hip, dir(p.lL, 19)), fL = add(kL, dir(p.sL, 19))
        let kR = add(hip, dir(p.lR, 19)), fR = add(kR, dir(p.sR, 19))
        var j = Joints(hip: hip, neck: neck, head: head, eL: eL, hL: hL, eR: eR, hR: hR, kL: kL, fL: fL, kR: kR, fR: fR)

        let floorY: CGFloat = 88
        let pts = [j.hip, j.neck, j.eL, j.hL, j.eR, j.hR, j.kL, j.fL, j.kR, j.fR, CGPoint(x: j.head.x, y: j.head.y + 3)]
        let maxY = pts.map(\.y).max() ?? 0
        let minX = min(pts.map(\.x).min() ?? 0, j.head.x - 6)
        let maxX = max(pts.map(\.x).max() ?? 0, j.head.x + 6)
        j.shift(50 - (minX + maxX) / 2 + CGFloat(p.dx), floorY - maxY - CGFloat(p.lift))
        return j
    }

    private func draw(ctx: GraphicsContext, size: CGSize, time: Double) {
        let s = min(size.width, size.height) / 100
        let ox = (size.width - 100 * s) / 2, oy = (size.height - 100 * s) / 2
        func pt(_ p: CGPoint) -> CGPoint { CGPoint(x: ox + p.x * s, y: oy + p.y * s) }
        func line(_ points: [CGPoint], _ c: Color, _ w: CGFloat) {
            var path = Path()
            path.addLines(points.map(pt))
            ctx.stroke(path, with: .color(c), style: StrokeStyle(lineWidth: w * s, lineCap: .round, lineJoin: .round))
        }

        let p = pose(at: time)
        let j = joints(p)
        let far = move.front ? color.opacity(0.85) : color.opacity(0.4)

        // Floor and shadow
        let floorY: CGFloat = 88
        line([CGPoint(x: 8, y: floorY + 3.5), CGPoint(x: 92, y: floorY + 3.5)], Color.white.opacity(0.08), 1)
        let shadowW = max(14, (max(j.fL.x, j.fR.x, j.hR.x) - min(j.fL.x, j.fR.x, j.hL.x)) + 10) * (1 - min(0.5, CGFloat(p.lift) / 50))
        let cx = (j.fL.x + j.fR.x) / 2
        ctx.fill(Path(ellipseIn: CGRect(x: ox + (cx - shadowW / 2) * s, y: oy + (floorY + 1.5) * s, width: shadowW * s, height: 4 * s)),
                 with: .color(Color.black.opacity(0.35)))

        if move.prop == .bar {
            let y = min(j.hL.y, j.hR.y) - 1
            line([CGPoint(x: 18, y: y), CGPoint(x: 82, y: y)], Theme.text2, 2.4)
        }
        if move.prop == .rope {
            let phase = (time / move.duration).truncatingRemainder(dividingBy: 1)
            let y = phase < 0.5 ? floorY + 2 : j.head.y - 12
            var path = Path()
            path.move(to: pt(j.hL))
            path.addQuadCurve(to: pt(j.hR), control: pt(CGPoint(x: (j.hL.x + j.hR.x) / 2, y: y)))
            ctx.stroke(path, with: .color(Theme.text2.opacity(0.7)), style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round))
        }

        line([j.neck, j.eL, j.hL], far, 5)
        line([j.hip, j.kL, j.fL], far, 6)
        line([j.hip, j.neck], color, 8)
        ctx.fill(Path(ellipseIn: CGRect(x: ox + (j.head.x - 6) * s, y: oy + (j.head.y - 6) * s, width: 12 * s, height: 12 * s)), with: .color(color))
        line([j.hip, j.kR, j.fR], color, 6)
        line([j.neck, j.eR, j.hR], color, 5)

        if move.prop == .stick {
            let dx = j.hR.x - j.hL.x, dy = j.hR.y - j.hL.y
            let len = max(0.001, sqrt(dx * dx + dy * dy))
            let ux = dx / len, uy = dy / len
            let reach: CGFloat = uy > 0.2 ? min(48, max(12, (floorY + 2 - j.hR.y) / uy)) : 30
            let blade = CGPoint(x: j.hR.x + ux * reach, y: j.hR.y + uy * reach)
            let side: CGFloat = ux >= 0 ? 1 : -1
            line([j.hL, blade], Theme.text.opacity(0.85), 2.2)
            line([blade, CGPoint(x: blade.x + 7 * side, y: blade.y)], Theme.text.opacity(0.85), 3)
        }
    }
}
