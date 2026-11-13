import Foundation
import simd

// 3D moves are data: Edgework/Data/moves.json. Poses use joint angles a coach would
// describe (hip flexion, knee bend, arm raise, torso twist…). tools/posepreview.py
// renders the same file with the same maths, so moves can be checked without a phone.

/// Every joint angle, in degrees. Body is the whole figure; L/R are the person's left and right.
struct Pose3D {
    static let fields = ["yaw", "bPitch", "bRoll", "bSpin", "pitch", "roll", "twist", "nod", "lift", "fwd", "side",
                         "sFL", "sAL", "eFL", "aRL", "sFR", "sAR", "eFR", "aRR",
                         "hFL", "hAL", "kFL", "hRL", "toeL", "plantL", "hFR", "hAR", "kFR", "hRR", "toeR", "plantR"]
    static let index: [String: Int] = Dictionary(uniqueKeysWithValues: fields.enumerated().map { ($1, $0) })
    static let negateOnMirror: Set<String> = ["yaw", "bRoll", "bSpin", "roll", "twist", "side"]

    var v = [Double](repeating: 0, count: fields.count)

    subscript(_ name: String) -> Double {
        get { Self.index[name].map { v[$0] } ?? 0 }
        set { if let i = Self.index[name] { v[i] = newValue } }
    }

    var mirrored: Pose3D {
        var m = self
        for f in Self.fields where f.hasSuffix("L") {
            let r = String(f.dropLast()) + "R"
            if Self.index[r] != nil { m[f] = self[r]; m[r] = self[f] }
        }
        for f in Self.negateOnMirror { m[f] = -self[f] }
        return m
    }

    static func lerp(_ a: Pose3D, _ b: Pose3D, _ u: Double) -> Pose3D {
        var p = a
        for i in p.v.indices { p.v[i] = a.v[i] + (b.v[i] - a.v[i]) * u }
        return p
    }
}

struct Motion {
    enum Prop: String { case stick, bar, ball, dumbbells, kettlebell, hurdle }
    var frames: [Pose3D]
    var weights: [Double]
    var duration: Double
    var prop: Prop?
    /// Where the move happens on the floor, so the camera stays on it.
    var center = SIMD2<Float>(0, 0)
    var height: Float = 80

    func pose(at time: Double) -> Pose3D {
        guard frames.count > 1 else { return frames.first ?? Pose3D() }
        let total = weights.reduce(0, +)
        var t = (time / duration).truncatingRemainder(dividingBy: 1)
        if t < 0 { t += 1 }
        t *= total
        for i in frames.indices {
            if t < weights[i] || i == frames.count - 1 {
                var x = min(1, t / max(0.0001, weights[i]))
                x = x * x * (3 - 2 * x)
                return Pose3D.lerp(frames[i], frames[(i + 1) % frames.count], x)
            }
            t -= weights[i]
        }
        return frames[0]
    }
}

// MARK: - Kinematics

enum Kinematics {
    private static func q(_ axis: SIMD3<Double>, _ deg: Double) -> simd_quatd { simd_quatd(angle: deg * .pi / 180, axis: axis) }
    private static func qx(_ d: Double) -> simd_quatd { q(SIMD3(1, 0, 0), d) }
    private static func qy(_ d: Double) -> simd_quatd { q(SIMD3(0, 1, 0), d) }
    private static func qz(_ d: Double) -> simd_quatd { q(SIMD3(0, 0, 1), d) }
    private static let down = SIMD3<Double>(0, -1, 0), up = SIMD3<Double>(0, 1, 0)

    /// Joint positions in figure units (about 80 tall standing), feet on y = 0. Figure faces +x, its right is +z.
    static func joints(_ p: Pose3D) -> [String: SIMD3<Double>] {
        let rb = qy(p["yaw"]) * qx(p["bRoll"]) * qz(-p["bPitch"]) * qy(p["bSpin"])
        let qt = rb * qx(p["roll"]) * qz(-p["pitch"]) * qy(-p["twist"])
        var j: [String: SIMD3<Double>] = [:]
        let spine = qt.act(up)
        j["pelvis"] = .zero
        j["chest"] = spine * 17
        let neck = spine * 26
        j["neck"] = neck
        let qh = qt * qz(-p["nod"])
        j["headBase"] = neck + qh.act(up * 3)
        j["head"] = neck + qh.act(up * 9)
        let shoulderBase = neck - spine * 2.5
        for (side, s) in [("L", -1.0), ("R", 1.0)] {
            let sh = shoulderBase + qt.act(SIMD3(0, 0, 7 * s))
            let a = qt * qx(-s * p["sA" + side]) * qz(p["sF" + side])
            let el = sh + a.act(down) * 14
            let fa = a * qy(s * p["aR" + side]) * qz(p["eF" + side])
            j["sh" + side] = sh
            j["el" + side] = el
            j["ha" + side] = el + fa.act(down) * 13
            let hp = rb.act(SIMD3(0, 0, 4.5 * s))
            let th = rb * qx(-s * p["hA" + side]) * qz(p["hF" + side])
            let kn = hp + th.act(down) * 19
            let sn = th * qy(s * p["hR" + side]) * qz(-p["kF" + side])
            let an = kn + sn.act(down) * 19
            let ft = rb * qx(-s * p["hA" + side]) * qy(-s * p["toe" + side]) * qz(90 - p["plant" + side])
            j["hip" + side] = hp
            j["kn" + side] = kn
            j["an" + side] = an
            j["to" + side] = an + ft.act(down) * 6
        }
        // Stand it on the floor, allowing for limb thickness, then lift and travel.
        let radius: [String: Double] = ["pelvis": 4.6, "chest": 5.2, "neck": 5.2, "head": 6, "headBase": 1.8]
        var lowest = Double.infinity
        for (k, v) in j {
            let r = radius[k] ?? (["to", "an", "kn", "ha", "el"].contains(String(k.prefix(2))) ? 2.4 : 3)
            lowest = min(lowest, v.y - r)
        }
        let shift = SIMD3(p["fwd"], -lowest + p["lift"], p["side"])
        for k in j.keys { j[k]! += shift }
        return j
    }
}

// MARK: - Library

enum MotionLibrary {
    private struct File: Decodable {
        var poses: [String: [String: Value]]
        var moves: [String: MoveDef]
        var exercises: [String: String]
        var categories: [String: String]?
    }
    private struct MoveDef: Decodable {
        var dur: Double
        var prop: String?
        var frames: [Frame]
    }
    private enum Frame: Decodable {
        case name(String)
        case spec([String: Value])
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self) { self = .name(s) } else { self = .spec(try c.decode([String: Value].self)) }
        }
    }
    private enum Value: Decodable {
        case num(Double), str(String), bool(Bool)
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let d = try? c.decode(Double.self) { self = .num(d) }
            else if let b = try? c.decode(Bool.self) { self = .bool(b) }
            else { self = .str(try c.decode(String.self)) }
        }
    }

    private static let file: File? = {
        guard let url = Bundle.main.url(forResource: "moves", withExtension: "json"),
              let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(File.self, from: raw)
    }()

    private static var cache: [String: Motion] = [:]
    private static let lock = NSLock()

    private static func resolve(_ spec: [String: Value], depth: Int = 0) -> Pose3D {
        var p = Pose3D()
        if case .str(let base)? = spec["base"], depth < 12, let f = file, let b = f.poses[base] {
            p = resolve(b, depth: depth + 1)
        }
        for (k, v) in spec {
            guard case .num(let d) = v else { continue }
            if k.hasPrefix("+") { p[String(k.dropFirst())] += d } else if Pose3D.index[k] != nil { p[k] = d }
        }
        if case .bool(true)? = spec["mirror"] { p = p.mirrored }
        return p
    }

    static func motion(named name: String) -> Motion? {
        lock.lock(); defer { lock.unlock() }
        if let m = cache[name] { return m }
        guard let f = file, let def = f.moves[name] else { return nil }
        var frames: [Pose3D] = []
        var weights: [Double] = []
        for fr in def.frames {
            switch fr {
            case .name(let n):
                frames.append(resolve(["base": .str(n)]))
                weights.append(1)
            case .spec(let s):
                frames.append(resolve(s))
                if case .num(let w)? = s["w"] { weights.append(w) } else { weights.append(1) }
            }
        }
        var m = Motion(frames: frames, weights: weights, duration: def.dur, prop: def.prop.flatMap(Motion.Prop.init(rawValue:)))
        // Centre the camera on the whole move, not one frame.
        var lo = SIMD2<Double>(.infinity, .infinity), hi = SIMD2<Double>(-.infinity, -.infinity)
        var top = 0.0
        for i in 0..<12 {
            for v in Kinematics.joints(m.pose(at: Double(i) / 12 * m.duration)).values {
                lo = simd_min(lo, SIMD2(v.x, v.z)); hi = simd_max(hi, SIMD2(v.x, v.z)); top = max(top, v.y)
            }
        }
        m.center = SIMD2<Float>(Float((lo.x + hi.x) / 2), Float((lo.y + hi.y) / 2))
        m.height = Float(top + 6)
        cache[name] = m
        return m
    }

    /// The move for an exercise: its own mapping, else its category's default, else standing.
    static func motion(for ex: Exercise) -> Motion {
        if let f = file {
            if let name = f.exercises[ex.id], let m = motion(named: name) { return m }
            if let name = f.categories?[ex.category.rawValue], let m = motion(named: name) { return m }
        }
        return motion(named: "idle") ?? Motion(frames: [Pose3D()], weights: [1], duration: 2)
    }

    static func hasMapping(_ id: String) -> Bool { file?.exercises[id] != nil }
}
