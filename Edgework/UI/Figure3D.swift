import SwiftUI
import SceneKit

// 3D demo figure. Uses the same poses as the 2D figure: side-view moves are
// played in the body's sagittal plane, front-view moves in the frontal plane,
// with real shoulder and hip width so you can orbit around it.

/// Builds and animates the mannequin. Runs on SceneKit's render loop.
final class FigureRig: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    private let body = SCNNode()
    private let lock = NSLock()
    private var _move: Move
    private var _paused = false
    private var clock: TimeInterval = 0
    private var lastTime: TimeInterval?

    private var bones: [Bone] = []
    private var spheres: [String: SCNNode] = [:]
    private let shadow = SCNNode()
    private let stick = SCNNode()
    private let blade = SCNNode()
    private let bar = SCNNode()
    private var materials: (near: SCNMaterial, far: SCNMaterial, skin: SCNMaterial)

    static let k: Float = 0.021  // 2D figure units → metres

    private struct Bone {
        let from: String, to: String
        let node: SCNNode
        let radius: Float
    }

    var move: Move {
        get { lock.lock(); defer { lock.unlock() }; return _move }
        set { lock.lock(); _move = newValue; clock = 0; lock.unlock() }
    }

    var paused: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _paused }
        set { lock.lock(); _paused = newValue; lock.unlock() }
    }

    init(move: Move, color: UIColor) {
        _move = move
        func mat(_ c: UIColor) -> SCNMaterial {
            let m = SCNMaterial()
            m.lightingModel = .physicallyBased
            m.diffuse.contents = c
            m.roughness.contents = 0.42
            m.metalness.contents = 0.05
            return m
        }
        materials = (mat(color), mat(color.mixed(with: .black, 0.32)), mat(color.mixed(with: .white, 0.18)))
        super.init()
        build()
        update(time: 0)
    }

    func setColor(_ c: UIColor) {
        materials.near.diffuse.contents = c
        materials.far.diffuse.contents = c.mixed(with: .black, 0.32)
        materials.skin.diffuse.contents = c.mixed(with: .white, 0.18)
    }

    // MARK: Build

    private func build() {
        scene.background.contents = UIColor.clear
        scene.rootNode.addChildNode(body)

        // Floor: a soft disc with a faint grid, fading out at the edge.
        let floor = SCNNode(geometry: SCNPlane(width: 3.4, height: 3.4))
        floor.eulerAngles.x = -.pi / 2
        let fm = SCNMaterial()
        fm.lightingModel = .constant
        fm.diffuse.contents = Self.floorImage()
        fm.isDoubleSided = true
        fm.writesToDepthBuffer = false
        floor.geometry?.firstMaterial = fm
        floor.renderingOrder = -2
        scene.rootNode.addChildNode(floor)

        let sm = SCNMaterial()
        sm.lightingModel = .constant
        sm.diffuse.contents = Self.shadowImage()
        sm.writesToDepthBuffer = false
        shadow.geometry = SCNPlane(width: 0.9, height: 0.9)
        shadow.geometry?.firstMaterial = sm
        shadow.eulerAngles.x = -.pi / 2
        shadow.position.y = 0.002
        shadow.renderingOrder = -1
        scene.rootNode.addChildNode(shadow)

        // Lights: soft ambient, a key from the front-top, a cool rim from behind.
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 420
        scene.rootNode.addChildNode(ambient)
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1100
        key.eulerAngles = SCNVector3(-0.9, 0.6, 0)
        scene.rootNode.addChildNode(key)
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 650
        rim.light?.color = UIColor(red: 0.7, green: 0.85, blue: 1, alpha: 1)
        rim.eulerAngles = SCNVector3(-0.4, .pi + 0.5, 0)
        scene.rootNode.addChildNode(rim)

        // Bones. Left limbs are the far side and slightly darker so they read apart.
        let k = Self.k
        func bone(_ from: String, _ to: String, _ r: Float, _ len: Float, _ m: SCNMaterial) {
            let cap = SCNCapsule(capRadius: CGFloat(r * k), height: CGFloat((len + 2 * r) * k))
            cap.radialSegmentCount = 18
            cap.firstMaterial = m
            let n = SCNNode(geometry: cap)
            body.addChildNode(n)
            bones.append(Bone(from: from, to: to, node: n, radius: r))
        }
        bone("hip", "chest", 4.6, 17, materials.near)
        bone("chest", "neck", 5.2, 8, materials.near)
        bone("shL", "shR", 3.2, 14, materials.near)
        bone("hipL", "hipR", 3.8, 9, materials.near)
        bone("neck", "headBase", 1.8, 3, materials.skin)
        bone("shL", "eL", 2.2, 14, materials.far)
        bone("eL", "hL", 1.9, 13, materials.far)
        bone("hipL", "kL", 3.1, 19, materials.far)
        bone("kL", "aL", 2.4, 19, materials.far)
        bone("aL", "toeL", 1.6, 6, materials.far)
        bone("shR", "eR", 2.2, 14, materials.near)
        bone("eR", "hR", 1.9, 13, materials.near)
        bone("hipR", "kR", 3.1, 19, materials.near)
        bone("kR", "aR", 2.4, 19, materials.near)
        bone("aR", "toeR", 1.6, 6, materials.near)

        func sphere(_ name: String, _ r: Float, _ m: SCNMaterial) {
            let s = SCNSphere(radius: CGFloat(r * k))
            s.segmentCount = 24
            s.firstMaterial = m
            let n = SCNNode(geometry: s)
            body.addChildNode(n)
            spheres[name] = n
        }
        sphere("head", 6, materials.skin)
        sphere("hL", 2.3, materials.far)
        sphere("hR", 2.3, materials.near)

        let propM = SCNMaterial()
        propM.lightingModel = .physicallyBased
        propM.diffuse.contents = UIColor(white: 0.85, alpha: 1)
        propM.roughness.contents = 0.6
        let shaft = SCNCylinder(radius: CGFloat(0.9 * k), height: 1)
        shaft.firstMaterial = propM
        stick.geometry = shaft
        let bl = SCNBox(width: CGFloat(11 * k), height: CGFloat(3 * k), length: CGFloat(0.8 * k), chamferRadius: CGFloat(0.4 * k))
        bl.firstMaterial = propM
        blade.geometry = bl
        let barG = SCNCylinder(radius: CGFloat(1 * k), height: CGFloat(60 * k))
        barG.firstMaterial = propM
        bar.geometry = barG
        for n in [stick, blade, bar] { n.isHidden = true; body.addChildNode(n) }
    }

    // MARK: Animate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        lock.lock()
        let dt = lastTime.map { min(0.1, time - $0) } ?? 0
        lastTime = time
        if !_paused { clock += dt }
        let t = clock
        lock.unlock()
        update(time: t)
    }

    private func pose(at time: Double, _ move: Move) -> Pose {
        let frames = move.frames
        guard frames.count > 1 else { return frames.first ?? Pose() }
        let p = (time / move.duration).truncatingRemainder(dividingBy: 1) * Double(frames.count)
        let i = Int(p) % frames.count
        var u = p - floor(p)
        u = u * u * (3 - 2 * u)
        return Pose.lerp(frames[i], frames[(i + 1) % frames.count], u)
    }

    private func update(time: Double) {
        let move = self.move
        let p = pose(at: time, move)
        let j = Self.joints(p, front: move.front)

        for b in bones {
            guard let a = j[b.from], let c = j[b.to] else { continue }
            let d = c - a
            let len = simd_length(d)
            guard len > 0.0001 else { continue }
            b.node.simdPosition = (a + c) / 2
            b.node.simdOrientation = Self.rotation(from: SIMD3(0, 1, 0), to: d / len)
        }
        spheres["head"]?.simdPosition = j["head"] ?? .zero
        spheres["hL"]?.simdPosition = j["hL"] ?? .zero
        spheres["hR"]?.simdPosition = j["hR"] ?? .zero

        // Shadow follows the feet, shrinks when airborne.
        let feet = ((j["aL"] ?? .zero) + (j["aR"] ?? .zero)) / 2
        shadow.simdPosition = SIMD3(feet.x, 0.002, feet.z)
        let s = Float(max(0.5, 1 - p.lift / 40))
        shadow.simdScale = SIMD3(s, s, s)

        stick.isHidden = move.prop != .stick
        bar.isHidden = move.prop != .bar
        blade.isHidden = stick.isHidden
        if move.prop == .stick, let hl = j["hL"], let hr = j["hR"] {
            var dir = hr - hl
            if simd_length(dir) < 0.001 { dir = SIMD3(0.3, -1, 0) }
            dir = simd_normalize(dir)
            if dir.y > -0.2 { dir = simd_normalize(dir + SIMD3(0, -0.6, 0)) }
            let reach = min(1.05, max(0.3, hr.y / max(0.2, -dir.y)))
            let end = hr + dir * reach
            let start = hl
            let len = simd_length(end - start)
            stick.simdPosition = (start + end) / 2
            stick.simdScale = SIMD3(1, len, 1)
            stick.simdOrientation = Self.rotation(from: SIMD3(0, 1, 0), to: (end - start) / max(0.001, len))
            let fwd = move.front ? SIMD3<Float>(0, 0, 1) : SIMD3<Float>(1, 0, 0)
            blade.simdPosition = SIMD3(end.x, 0.035, end.z) + fwd * 0.08
            blade.simdOrientation = simd_quatf(angle: move.front ? .pi / 2 : 0, axis: SIMD3(0, 1, 0))
        }
        if move.prop == .bar, let hl = j["hL"], let hr = j["hR"] {
            bar.simdPosition = (hl + hr) / 2 + SIMD3(0, 0.02, 0)
            bar.simdOrientation = Self.rotation(from: SIMD3(0, 1, 0), to: move.front ? SIMD3(1, 0, 0) : SIMD3(0, 0, 1))
        }
    }

    /// Forward kinematics in 3D. Same angle convention as the 2D figure: 0° down, 90° forward (or right), 180° up.
    static func joints(_ p: Pose, front: Bool) -> [String: SIMD3<Float>] {
        let k = Self.k
        // Side view: angles swing in the x–y plane, left/right sit apart on z.
        // Front view: angles swing in the x–y plane facing the camera, left/right sit apart on x.
        let lateral: SIMD3<Float> = front ? SIMD3(1, 0, 0) : SIMD3(0, 0, 1)
        let facing: SIMD3<Float> = front ? SIMD3(0, 0, 1) : SIMD3(1, 0, 0)
        func dir(_ a: Double) -> SIMD3<Float> {
            let r = a * .pi / 180
            return SIMD3(Float(sin(r)), Float(-cos(r)), 0)
        }
        // Side: right limbs are the near side (+z). Front: "L" angles point screen-left (−x).
        let sideL: Float = -1, sideR: Float = 1

        var j: [String: SIMD3<Float>] = [:]
        let hip = SIMD3<Float>(0, 0, 0)
        let spine = dir(p.t)
        let neck = hip + spine * 26 * k
        j["hip"] = hip
        j["chest"] = hip + spine * 17 * k
        j["neck"] = neck
        let headDir = dir(p.h ?? p.t)
        j["headBase"] = neck + headDir * 3 * k
        j["head"] = neck + headDir * 9 * k
        let shoulderBase = neck - spine * 2.5 * k
        let shL = shoulderBase + lateral * sideL * 7 * k
        let shR = shoulderBase + lateral * sideR * 7 * k
        j["shL"] = shL; j["shR"] = shR
        let eL = shL + dir(p.aL) * 14 * k, eR = shR + dir(p.aR) * 14 * k
        j["eL"] = eL; j["eR"] = eR
        j["hL"] = eL + dir(p.fL) * 13 * k
        j["hR"] = eR + dir(p.fR) * 13 * k
        let hipL = hip + lateral * sideL * 4.5 * k
        let hipR = hip + lateral * sideR * 4.5 * k
        j["hipL"] = hipL; j["hipR"] = hipR
        let kL = hipL + dir(p.lL) * 19 * k, kR = hipR + dir(p.lR) * 19 * k
        j["kL"] = kL; j["kR"] = kR
        let aL = kL + dir(p.sL) * 19 * k, aR = kR + dir(p.sR) * 19 * k
        j["aL"] = aL; j["aR"] = aR
        // Feet point forward, square to the shin.
        func foot(_ shin: Double) -> SIMD3<Float> {
            if front { return simd_normalize(facing * 0.95 + SIMD3(0, -0.2, 0)) }
            return dir(shin + 90)
        }
        j["toeL"] = aL + foot(p.sL) * 6 * k
        j["toeR"] = aR + foot(p.sR) * 6 * k

        // Stand it on the floor, centred like the 2D figure.
        let pts = Array(j.values) + [j["head"]! - SIMD3(0, 6 * k, 0)]
        let minY = pts.map(\.y).min() ?? 0
        let minX = pts.map(\.x).min() ?? 0, maxX = pts.map(\.x).max() ?? 0
        let shift = SIMD3<Float>(-(minX + maxX) / 2 + Float(p.dx) * k, -minY + Float(p.lift) * k, 0)
        for key in j.keys { j[key]! += shift }
        return j
    }

    static func rotation(from a: SIMD3<Float>, to b: SIMD3<Float>) -> simd_quatf {
        let d = simd_dot(a, b)
        if d < -0.9999 { return simd_quatf(angle: .pi, axis: SIMD3(1, 0, 0)) }
        return simd_quatf(from: a, to: b)
    }

    // MARK: Textures

    private static func floorImage() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            let colors = [UIColor(white: 1, alpha: 0.10).cgColor, UIColor(white: 1, alpha: 0.0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                c.drawRadialGradient(g, startCenter: CGPoint(x: 256, y: 256), startRadius: 0, endCenter: CGPoint(x: 256, y: 256), endRadius: 256, options: [])
            }
            c.saveGState()
            c.addEllipse(in: CGRect(x: 8, y: 8, width: 496, height: 496))
            c.clip()
            c.setStrokeColor(UIColor(white: 1, alpha: 0.07).cgColor)
            c.setLineWidth(1.5)
            for i in stride(from: 0, through: 512, by: 32) {
                c.move(to: CGPoint(x: i, y: 0)); c.addLine(to: CGPoint(x: i, y: 512))
                c.move(to: CGPoint(x: 0, y: i)); c.addLine(to: CGPoint(x: 512, y: i))
            }
            c.strokePath()
            c.restoreGState()
        }
    }

    private static func shadowImage() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(white: 0, alpha: 0.5).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawRadialGradient(g, startCenter: CGPoint(x: 128, y: 128), startRadius: 0,
                                                 endCenter: CGPoint(x: 128, y: 128), endRadius: 128, options: [])
            }
        }
    }
}

private extension UIColor {
    func mixed(with other: UIColor, _ amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * amount, green: g1 + (g2 - g1) * amount, blue: b1 + (b2 - b1) * amount, alpha: a1)
    }
}

// MARK: - SwiftUI

enum FigureAngle: String, CaseIterable, Identifiable {
    case threeQuarter, front, side
    var id: String { rawValue }
    var title: String {
        switch self {
        case .threeQuarter: "3D"
        case .front: "Front"
        case .side: "Side"
        }
    }
}

/// Drag to orbit, pinch to zoom. The buttons snap back to a clean angle.
struct Figure3DView: View {
    let move: Move
    let moveID: String
    var color: Color
    var animate = true
    var showControls = true
    @State private var angle = FigureAngle.threeQuarter
    @State private var snap = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FigureSceneView(move: move, moveID: moveID, color: UIColor(color), paused: !animate, angle: angle, snap: snap)
            if showControls {
                HStack(spacing: 4) {
                    ForEach(FigureAngle.allCases) { a in
                        Button {
                            angle = a
                            snap += 1
                        } label: {
                            Text(a.title)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(angle == a ? Theme.bg : Theme.text2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(angle == a ? color : Theme.surface2.opacity(0.9)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if showControls {
                Label("Drag to rotate", systemImage: "rotate.3d")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.text3)
                    .padding(8)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct FigureSceneView: UIViewRepresentable {
    let move: Move
    let moveID: String
    let color: UIColor
    let paused: Bool
    let angle: FigureAngle
    let snap: Int

    final class Coordinator {
        var rig: FigureRig
        var moveID: String
        var snap = -1
        init(rig: FigureRig, moveID: String) { self.rig = rig; self.moveID = moveID }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rig: FigureRig(move: move, color: color), moveID: moveID)
    }

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero)
        v.backgroundColor = .clear
        v.scene = context.coordinator.rig.scene
        v.delegate = context.coordinator.rig
        v.isPlaying = true
        v.rendersContinuously = true
        v.preferredFramesPerSecond = 60
        v.antialiasingMode = .multisampling4X
        v.allowsCameraControl = true
        v.defaultCameraController.interactionMode = .orbitTurntable
        v.defaultCameraController.inertiaEnabled = true
        v.defaultCameraController.maximumVerticalAngle = 80
        v.defaultCameraController.minimumVerticalAngle = -10
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 34
        cam.camera?.zNear = 0.05
        cam.camera?.wantsHDR = false
        context.coordinator.rig.scene.rootNode.addChildNode(cam)
        v.pointOfView = cam
        place(cam, v, front: move.front)
        context.coordinator.snap = snap
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        let c = context.coordinator
        c.rig.paused = paused
        c.rig.setColor(color)
        if c.moveID != moveID {
            c.moveID = moveID
            c.rig.move = move
            if let cam = v.pointOfView { place(cam, v, front: move.front) }
        }
        if c.snap != snap {
            c.snap = snap
            if let cam = v.pointOfView {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.45
                place(cam, v, front: move.front)
                SCNTransaction.commit()
            }
        }
    }

    /// Camera positions are relative to how the move was authored (side or front view).
    private func place(_ cam: SCNNode, _ v: SCNView, front: Bool) {
        let target = SCNVector3(0, 0.72, 0)
        let dist: Float = 3.15
        let az: Float
        switch angle {
        case .front: az = front ? 0 : .pi / 2
        case .side: az = front ? .pi / 2 : 0
        case .threeQuarter: az = front ? 0.6 : 0.75
        }
        // az = 0 looks from +z; side-view moves face +x, so their front is az = π/2.
        let elev: Float = angle == .threeQuarter ? 0.22 : 0.08
        cam.position = SCNVector3(target.x + dist * cos(elev) * sin(az), target.y + dist * sin(elev), target.z + dist * cos(elev) * cos(az))
        cam.look(at: target)
        v.defaultCameraController.target = target
    }
}

// MARK: - Top-down stickhandling

/// Bird's-eye view of the stick, blade and puck. The blade always cups the puck from the side it's pulling away from.
struct StickTopDownView: View {
    let exerciseID: String
    var color: Color
    var animate = true

    private enum Pattern { case sideToSide, wideNarrow, figure8, circle, toeDrag, frontBack, weave, betweenLegs, protect, combo, quick }

    private var pattern: Pattern {
        switch exerciseID {
        case "wide-narrow": .wideNarrow
        case "figure-8", "figure8-one-hand": .figure8
        case "puck-circle": .circle
        case "toe-drag", "toe-drag-around": .toeDrag
        case "obstacle-weave", "speed-cones", "puck-maze": .weave
        case "between-legs", "skate-to-stick": .betweenLegs
        case "puck-protection", "backhand-cradle": .protect
        case "dangle-combo": .combo
        case "quick-hands": .quick
        case "one-hand", "heads-up", "eyes-closed-hands": .sideToSide
        default: .sideToSide
        }
    }

    private var period: Double {
        switch pattern {
        case .quick: 0.7
        case .sideToSide: 1.3
        case .wideNarrow: 3.2
        case .figure8: 3.4
        case .circle: 2.6
        case .toeDrag: 1.8
        case .frontBack: 1.4
        case .weave: 5.0
        case .betweenLegs: 2.6
        case .protect: 3.0
        case .combo: 5.5
        }
    }

    private var obstacles: [CGPoint] {
        switch pattern {
        case .figure8: [CGPoint(x: 37, y: 46), CGPoint(x: 63, y: 46)]
        case .circle: [CGPoint(x: 50, y: 44)]
        case .toeDrag: [CGPoint(x: 52, y: 40)]
        case .weave: [CGPoint(x: 50, y: 22), CGPoint(x: 50, y: 40), CGPoint(x: 50, y: 58)]
        default: []
        }
    }

    /// Puck position for phase u in 0..<1, in a 100×100 box. Player stands at the bottom, facing up.
    private func puck(_ u: Double) -> CGPoint {
        let tau = 2 * Double.pi
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        switch pattern {
        case .sideToSide, .quick:
            let w = pattern == .quick ? 9.0 : 16
            return p(50 + w * sin(tau * u), 50 + 2 * cos(2 * tau * u))
        case .wideNarrow:
            let w = 10 + 14 * (0.5 + 0.5 * sin(tau * u / 1))
            return p(50 + w * sin(tau * u * 4), 50)
        case .figure8:
            return p(50 + 24 * sin(tau * u), 46 + 11 * sin(2 * tau * u))
        case .circle:
            return p(50 + 15 * cos(tau * u), 44 + 13 * sin(tau * u))
        case .toeDrag:
            // Out wide on the forehand, pulled across with the toe, pushed back out.
            let s = u < 0.5 ? u * 2 : 2 - u * 2
            let e = s * s * (3 - 2 * s)
            return p(70 - 38 * e, 48 - 10 * sin(Double.pi * e))
        case .frontBack:
            return p(56, 46 + 16 * sin(tau * u))
        case .weave:
            let y = 68 - 54 * (u < 0.5 ? u * 2 : 2 - u * 2)
            return p(50 + 11 * sin((68 - y) / 18 * Double.pi), y)
        case .betweenLegs:
            let s = u < 0.5 ? u * 2 : 2 - u * 2
            return p(50 + 14 * sin(Double.pi * s * 2) * (1 - s), 48 + 34 * s)
        case .protect:
            return p(72 + 6 * sin(tau * u), 64 + 10 * sin(tau * u * 2))
        case .combo:
            if u < 0.4 { return p(50 + 16 * sin(tau * u / 0.4 * 2), 48) }
            let s = (u - 0.4) / 0.6
            let e = s < 0.5 ? s * 2 : 2 - s * 2
            return p(66 - 34 * e, 48 - 8 * sin(Double.pi * e))
        }
    }

    var body: some View {
        TimelineView(.animation(paused: !animate)) { tl in
            Canvas { ctx, size in draw(ctx, size, tl.date.timeIntervalSinceReferenceDate) }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, _ time: Double) {
        let s = min(size.width, size.height) / 100
        let ox = (size.width - 100 * s) / 2, oy = (size.height - 100 * s) / 2
        func pt(_ p: CGPoint) -> CGPoint { CGPoint(x: ox + p.x * s, y: oy + p.y * s) }
        func circle(_ c: CGPoint, _ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: ox + (c.x - r) * s, y: oy + (c.y - r) * s, width: 2 * r * s, height: 2 * r * s)) }

        // Ice / floor with faint boards lines.
        let rink = Path(roundedRect: CGRect(x: ox + 4 * s, y: oy + 4 * s, width: 92 * s, height: 92 * s), cornerRadius: 18 * s)
        ctx.fill(rink, with: .color(Color.white.opacity(0.04)))
        ctx.stroke(rink, with: .color(Color.white.opacity(0.08)), lineWidth: 1)
        var line = Path()
        line.move(to: pt(CGPoint(x: 6, y: 30))); line.addLine(to: pt(CGPoint(x: 94, y: 30)))
        ctx.stroke(line, with: .color(Theme.ice.opacity(0.18)), style: StrokeStyle(lineWidth: 1.4 * s, dash: [3 * s, 3 * s]))

        for o in obstacles {
            ctx.fill(circle(o, 3.2), with: .color(Theme.amber.opacity(0.9)))
            ctx.stroke(circle(o, 3.2), with: .color(Color.black.opacity(0.4)), lineWidth: 0.8)
        }

        let u = (time / period).truncatingRemainder(dividingBy: 1)
        let pk = puck(u)
        let ahead = puck((u + 0.01).truncatingRemainder(dividingBy: 1))
        var vx = ahead.x - pk.x, vy = ahead.y - pk.y
        let vl = max(0.0001, sqrt(vx * vx + vy * vy))
        vx /= vl; vy /= vl

        // Trail
        var trail = Path()
        for i in 0...24 {
            let q = puck((u - Double(i) * 0.012 + 1).truncatingRemainder(dividingBy: 1))
            if i == 0 { trail.move(to: pt(q)) } else { trail.addLine(to: pt(q)) }
        }
        ctx.stroke(trail, with: .color(color.opacity(0.25)), style: StrokeStyle(lineWidth: 2.4 * s, lineCap: .round, lineJoin: .round))

        // Skates and body from above.
        let feet = [CGPoint(x: 41, y: 86), CGPoint(x: 59, y: 86)]
        for f in feet {
            ctx.fill(Path(roundedRect: CGRect(x: ox + (f.x - 3) * s, y: oy + (f.y - 7) * s, width: 6 * s, height: 14 * s), cornerRadius: 3 * s),
                     with: .color(Theme.text2.opacity(0.55)))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: ox + 36 * s, y: oy + 76 * s, width: 28 * s, height: 14 * s)), with: .color(color.opacity(0.35)))
        ctx.fill(circle(CGPoint(x: 50, y: 81), 5.5), with: .color(color.opacity(0.9)))

        // Blade cups the puck from behind its motion.
        let blade = CGPoint(x: pk.x - vx * 4.6, y: pk.y - vy * 4.6)
        let nx = -vy, ny = vx   // blade runs across the motion
        let half: CGFloat = 6.5
        let heel = CGPoint(x: blade.x - nx * half * (nx >= 0 ? 1 : -1), y: blade.y - ny * half * (nx >= 0 ? 1 : -1))
        let toe = CGPoint(x: blade.x + nx * half * (nx >= 0 ? 1 : -1), y: blade.y + ny * half * (nx >= 0 ? 1 : -1))
        let hands = CGPoint(x: 50 + (pk.x - 50) * 0.25, y: 74)
        var shaft = Path()
        shaft.move(to: pt(hands)); shaft.addLine(to: pt(heel))
        ctx.stroke(shaft, with: .color(Theme.text.opacity(0.85)), style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
        var bl = Path()
        bl.move(to: pt(heel)); bl.addLine(to: pt(toe))
        ctx.stroke(bl, with: .color(Theme.text), style: StrokeStyle(lineWidth: 3.2 * s, lineCap: .round))
        ctx.fill(circle(hands, 2.4), with: .color(color))

        // Puck
        ctx.fill(circle(CGPoint(x: pk.x + 0.6, y: pk.y + 0.8), 3.4), with: .color(Color.black.opacity(0.35)))
        ctx.fill(circle(pk, 3.2), with: .color(Color(white: 0.08)))
        ctx.stroke(circle(pk, 3.2), with: .color(Color.white.opacity(0.35)), lineWidth: 0.8)
    }
}
