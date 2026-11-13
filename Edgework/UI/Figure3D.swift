import SwiftUI
import SceneKit
import UIKit

// 3D demo figure. Moves come from Motion3D (moves.json). The camera is a plain orbit
// (yaw, pitch, distance) that's always level, so it can never roll sideways.

/// Builds and animates the mannequin. Runs on SceneKit's render loop.
final class FigureRig: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    let camera = SCNNode()
    private let body = SCNNode()
    private let lock = NSLock()
    private var _motion: Motion
    private var _paused = false
    private var _speed = 1.0
    private var clock: TimeInterval = 0
    private var lastTime: TimeInterval?

    // Orbit state. Target values are set by gestures/buttons; current values ease toward them each frame.
    private var yaw: Float = 0.9, pitch: Float = 0.2, dist: Float = 3.4
    private var yawT: Float = 0.9, pitchT: Float = 0.2, distT: Float = 3.4
    private var focus = SIMD3<Float>(0, 0.8, 0)

    private var bones: [Bone] = []
    private var spheres: [String: SCNNode] = [:]
    private let shadow = SCNNode()
    private var props: [Motion.Prop: SCNNode] = [:]
    private let dumbbellL = SCNNode(), dumbbellR = SCNNode()
    private var materials: (near: SCNMaterial, far: SCNMaterial, skin: SCNMaterial)

    static let k: Float = 0.021  // figure units → metres

    private struct Bone {
        let from: String, to: String
        let node: SCNNode
    }

    init(motion: Motion, color: UIColor) {
        _motion = motion
        func mat(_ c: UIColor) -> SCNMaterial {
            let m = SCNMaterial()
            m.lightingModel = .physicallyBased
            m.diffuse.contents = c
            m.roughness.contents = 0.42
            m.metalness.contents = 0.05
            return m
        }
        materials = (mat(color), mat(color.mixed(with: .black, 0.3)), mat(color.mixed(with: .white, 0.25)))
        super.init()
        build()
        setMotion(motion)
        update(time: 0)
        placeCamera()
    }

    // MARK: Thread-safe controls

    func setMotion(_ m: Motion) {
        lock.lock()
        _motion = m
        clock = 0
        focus = SIMD3(m.center.x * Self.k, min(0.85, m.height * Self.k * 0.5), m.center.y * Self.k)
        lock.unlock()
    }

    var paused: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _paused }
        set { lock.lock(); _paused = newValue; lock.unlock() }
    }

    var speed: Double {
        get { lock.lock(); defer { lock.unlock() }; return _speed }
        set { lock.lock(); _speed = newValue; lock.unlock() }
    }

    /// Snap to a named angle. Yaw 0 looks at the figure's right side; π/2 looks at its front.
    func look(yaw y: Float, pitch p: Float) {
        lock.lock()
        // Go the short way round.
        var target = y
        while target - yaw > .pi { target -= 2 * .pi }
        while target - yaw < -.pi { target += 2 * .pi }
        yawT = target; pitchT = p; distT = 3.4
        lock.unlock()
    }

    func drag(dx: Float, dy: Float) {
        lock.lock()
        yaw -= dx * 0.008; yawT = yaw
        pitch = max(-0.15, min(1.3, pitch + dy * 0.006)); pitchT = pitch
        lock.unlock()
    }

    func zoom(_ scale: Float) {
        lock.lock()
        dist = max(1.6, min(7, dist / scale)); distT = dist
        lock.unlock()
    }

    func setColor(_ c: UIColor) {
        materials.near.diffuse.contents = c
        materials.far.diffuse.contents = c.mixed(with: .black, 0.3)
        materials.skin.diffuse.contents = c.mixed(with: .white, 0.25)
    }

    // MARK: Build

    private func build() {
        scene.background.contents = UIColor.clear
        scene.rootNode.addChildNode(body)

        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 34
        camera.camera?.zNear = 0.05
        scene.rootNode.addChildNode(camera)

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
        shadow.geometry = SCNPlane(width: 1.0, height: 1.0)
        shadow.geometry?.firstMaterial = sm
        shadow.eulerAngles.x = -.pi / 2
        shadow.renderingOrder = -1
        scene.rootNode.addChildNode(shadow)

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

        let k = Self.k
        func bone(_ from: String, _ to: String, _ r: Float, _ len: Float, _ m: SCNMaterial) {
            let cap = SCNCapsule(capRadius: CGFloat(r * k), height: CGFloat((len + 2 * r) * k))
            cap.radialSegmentCount = 18
            cap.firstMaterial = m
            let n = SCNNode(geometry: cap)
            body.addChildNode(n)
            bones.append(Bone(from: from, to: to, node: n))
        }
        bone("pelvis", "chest", 4.6, 17, materials.near)
        bone("chest", "neck", 5.2, 9, materials.near)
        bone("shL", "shR", 3.2, 14, materials.near)
        bone("hipL", "hipR", 3.8, 9, materials.near)
        bone("neck", "headBase", 1.8, 3, materials.skin)
        for (side, m) in [("L", materials.far), ("R", materials.near)] {
            bone("sh" + side, "el" + side, 2.2, 14, m)
            bone("el" + side, "ha" + side, 1.9, 13, m)
            bone("hip" + side, "kn" + side, 3.1, 19, m)
            bone("kn" + side, "an" + side, 2.4, 19, m)
            bone("an" + side, "to" + side, 1.6, 6, m)
        }
        func sphere(_ name: String, _ r: Float, _ m: SCNMaterial) {
            let s = SCNSphere(radius: CGFloat(r * k))
            s.segmentCount = 24
            s.firstMaterial = m
            let n = SCNNode(geometry: s)
            body.addChildNode(n)
            spheres[name] = n
        }
        sphere("head", 6, materials.skin)
        sphere("haL", 2.3, materials.far)
        sphere("haR", 2.3, materials.near)

        // Props
        let pm = SCNMaterial()
        pm.lightingModel = .physicallyBased
        pm.diffuse.contents = UIColor(white: 0.82, alpha: 1)
        pm.roughness.contents = 0.6
        let dark = SCNMaterial()
        dark.lightingModel = .physicallyBased
        dark.diffuse.contents = UIColor(white: 0.18, alpha: 1)
        dark.roughness.contents = 0.5

        let stick = SCNNode()
        let shaft = SCNNode(geometry: SCNCylinder(radius: CGFloat(0.9 * k), height: 1))
        shaft.geometry?.firstMaterial = pm
        shaft.name = "shaft"
        let blade = SCNNode(geometry: SCNBox(width: CGFloat(11 * k), height: CGFloat(3 * k), length: CGFloat(0.8 * k), chamferRadius: CGFloat(0.4 * k)))
        blade.geometry?.firstMaterial = pm
        blade.name = "blade"
        stick.addChildNode(shaft)
        stick.addChildNode(blade)
        props[.stick] = stick

        let bar = SCNNode(geometry: SCNCylinder(radius: CGFloat(1 * k), height: CGFloat(60 * k)))
        bar.geometry?.firstMaterial = pm
        props[.bar] = bar

        let ball = SCNNode(geometry: SCNSphere(radius: CGFloat(5.5 * k)))
        ball.geometry?.firstMaterial = dark
        props[.ball] = ball

        let kb = SCNNode(geometry: SCNSphere(radius: CGFloat(4.5 * k)))
        kb.geometry?.firstMaterial = dark
        props[.kettlebell] = kb

        let dbs = SCNNode()
        for n in [dumbbellL, dumbbellR] {
            let g = SCNCapsule(capRadius: CGFloat(1.8 * k), height: CGFloat(9 * k))
            g.firstMaterial = dark
            n.geometry = g
            dbs.addChildNode(n)
        }
        props[.dumbbells] = dbs

        let hurdle = SCNNode()
        let barG = SCNBox(width: CGFloat(1.5 * k), height: CGFloat(3 * k), length: CGFloat(42 * k), chamferRadius: 0)
        barG.firstMaterial = pm
        let top = SCNNode(geometry: barG)
        top.position = SCNVector3(0, 30 * k, 0)
        hurdle.addChildNode(top)
        for z in [-20, 20] as [Float] {
            let leg = SCNNode(geometry: SCNCylinder(radius: CGFloat(0.7 * k), height: CGFloat(30 * k)))
            leg.geometry?.firstMaterial = dark
            leg.position = SCNVector3(0, 15 * k, z * k)
            hurdle.addChildNode(leg)
        }
        props[.hurdle] = hurdle

        for n in props.values { n.isHidden = true; scene.rootNode.addChildNode(n) }
    }

    // MARK: Animate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        lock.lock()
        let dt = lastTime.map { min(0.1, time - $0) } ?? 0
        lastTime = time
        if !_paused { clock += dt * _speed }
        let t = clock
        lock.unlock()
        update(time: t)
        placeCamera()
    }

    private func placeCamera() {
        lock.lock()
        let e: Float = 0.16
        yaw += (yawT - yaw) * e
        pitch += (pitchT - pitch) * e
        dist += (distT - dist) * e
        let y = yaw, p = pitch, d = dist, f = focus
        lock.unlock()
        let pos = f + SIMD3(d * cos(p) * sin(y), d * sin(p), d * cos(p) * cos(y))
        camera.simdPosition = pos
        camera.simdLook(at: f, up: SIMD3(0, 1, 0), localFront: SIMD3(0, 0, -1))
    }

    private func update(time: Double) {
        lock.lock()
        let motion = _motion
        lock.unlock()
        let p = motion.pose(at: time)
        let raw = Kinematics.joints(p)
        var j: [String: SIMD3<Float>] = [:]
        for (key, v) in raw { j[key] = SIMD3<Float>(Float(v.x), Float(v.y), Float(v.z)) * Self.k }

        for b in bones {
            guard let a = j[b.from], let c = j[b.to] else { continue }
            let d = c - a
            let len = simd_length(d)
            guard len > 0.0001 else { continue }
            b.node.simdPosition = (a + c) / 2
            b.node.simdOrientation = Self.rotation(from: SIMD3(0, 1, 0), to: d / len)
        }
        for name in ["head", "haL", "haR"] { spheres[name]?.simdPosition = j[name] ?? .zero }

        let feet = ((j["anL"] ?? .zero) + (j["anR"] ?? .zero)) / 2
        shadow.simdPosition = SIMD3(feet.x, 0.002, feet.z)
        let s = Float(max(0.5, 1 - p["lift"] / 40))
        shadow.simdScale = SIMD3(s, s, s)

        for (kind, node) in props { node.isHidden = kind != motion.prop }
        guard let prop = motion.prop, let hl = j["haL"], let hr = j["haR"] else { return }
        let lateral = simd_act(simd_quatf(angle: Float(p["yaw"] * .pi / 180), axis: SIMD3(0, 1, 0)), SIMD3<Float>(0, 0, 1))
        let forward = simd_cross(SIMD3<Float>(0, 1, 0), lateral)
        switch prop {
        case .stick:
            guard let node = props[.stick], let shaft = node.childNode(withName: "shaft", recursively: false),
                  let blade = node.childNode(withName: "blade", recursively: false) else { return }
            var dir = hr - hl
            if simd_length(dir) < 0.001 { dir = SIMD3(0.3, -1, 0) }
            dir = simd_normalize(dir)
            if dir.y > -0.25 { dir = simd_normalize(dir + SIMD3(0, -0.7, 0)) }
            let reach = min(1.1, max(0.3, hr.y / max(0.2, -dir.y)))
            let end = hr + dir * reach
            let len = simd_length(end - hl)
            shaft.simdPosition = (hl + end) / 2
            shaft.simdScale = SIMD3(1, len, 1)
            shaft.simdOrientation = Self.rotation(from: SIMD3(0, 1, 0), to: (end - hl) / max(0.001, len))
            var flat = SIMD3<Float>(dir.x, 0, dir.z)
            if simd_length(flat) < 0.01 { flat = forward }
            flat = simd_normalize(flat)
            blade.simdPosition = SIMD3(end.x, 0.032, end.z) + flat * 0.07
            blade.simdOrientation = Self.rotation(from: SIMD3(1, 0, 0), to: flat)
        case .bar:
            props[.bar]?.simdPosition = (hl + hr) / 2 + SIMD3(0, 0.02, 0)
            props[.bar]?.simdOrientation = Self.rotation(from: SIMD3(0, 1, 0), to: lateral)
        case .ball:
            props[.ball]?.simdPosition = (hl + hr) / 2 + forward * 0.06
        case .kettlebell:
            props[.kettlebell]?.simdPosition = (hl + hr) / 2 + SIMD3(0, -0.08, 0)
        case .dumbbells:
            dumbbellL.simdPosition = hl
            dumbbellR.simdPosition = hr
            dumbbellL.simdOrientation = Self.rotation(from: SIMD3(0, 1, 0), to: lateral)
            dumbbellR.simdOrientation = dumbbellL.simdOrientation
        case .hurdle:
            props[.hurdle]?.simdPosition = SIMD3(motion.center.x * Self.k, 0, motion.center.y * Self.k) + forward * 0.42
            props[.hurdle]?.simdOrientation = simd_quatf(angle: Float(p["yaw"] * .pi / 180), axis: SIMD3(0, 1, 0))
        }
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
    case threeQuarter, front, side, back
    var id: String { rawValue }
    var title: String {
        switch self {
        case .threeQuarter: "3D"
        case .front: "Front"
        case .side: "Side"
        case .back: "Back"
        }
    }
    /// Camera yaw/pitch. The figure faces +x, so its front is yaw π/2.
    var yawPitch: (Float, Float) {
        switch self {
        case .threeQuarter: (0.9, 0.22)
        case .front: (.pi / 2, 0.08)
        case .side: (0, 0.08)
        case .back: (-.pi / 2, 0.12)
        }
    }
}

/// Drag to orbit, pinch to zoom. The buttons swing the camera round to a clean angle.
struct Figure3DView: View {
    let motion: Motion
    let moveID: String
    var color: Color
    var animate = true
    var speed = 1.0
    var showControls = true
    @State private var angle = FigureAngle.threeQuarter
    @State private var snap = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FigureSceneView(motion: motion, moveID: moveID, color: UIColor(color), paused: !animate, speed: speed, angle: angle, snap: snap)
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
        .accessibilityHidden(true)
    }
}

private struct FigureSceneView: UIViewRepresentable {
    let motion: Motion
    let moveID: String
    let color: UIColor
    let paused: Bool
    let speed: Double
    let angle: FigureAngle
    let snap: Int

    final class Coordinator: NSObject {
        let rig: FigureRig
        var moveID: String
        var snap = -1
        private var lastPan = CGPoint.zero

        init(rig: FigureRig, moveID: String) { self.rig = rig; self.moveID = moveID }

        @objc func pan(_ g: UIPanGestureRecognizer) {
            let t = g.translation(in: g.view)
            if g.state == .began { lastPan = .zero }
            rig.drag(dx: Float(t.x - lastPan.x), dy: Float(t.y - lastPan.y))
            lastPan = t
        }

        @objc func pinch(_ g: UIPinchGestureRecognizer) {
            rig.zoom(Float(g.scale))
            g.scale = 1
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rig: FigureRig(motion: motion, color: color), moveID: moveID)
    }

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero)
        let c = context.coordinator
        v.backgroundColor = .clear
        v.scene = c.rig.scene
        v.pointOfView = c.rig.camera
        v.delegate = c.rig
        v.isPlaying = true
        v.rendersContinuously = true
        v.preferredFramesPerSecond = 60
        v.antialiasingMode = .multisampling4X
        v.allowsCameraControl = false
        v.addGestureRecognizer(UIPanGestureRecognizer(target: c, action: #selector(Coordinator.pan(_:))))
        v.addGestureRecognizer(UIPinchGestureRecognizer(target: c, action: #selector(Coordinator.pinch(_:))))
        let (y, p) = angle.yawPitch
        c.rig.look(yaw: y, pitch: p)
        c.snap = snap
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        let c = context.coordinator
        c.rig.paused = paused
        c.rig.speed = speed
        c.rig.setColor(color)
        if c.moveID != moveID {
            c.moveID = moveID
            c.rig.setMotion(motion)
        }
        if c.snap != snap {
            c.snap = snap
            let (y, p) = angle.yawPitch
            c.rig.look(yaw: y, pitch: p)
        }
    }
}

/// Animation speed for the demo figures, shared by every exercise.
struct SpeedSlider: View {
    @EnvironmentObject var store: Store
    var color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "tortoise.fill").font(.caption).foregroundStyle(Theme.text3)
            Slider(value: $store.data.settings.figureSpeed, in: 0.25...2, step: 0.25)
                .tint(color)
            Image(systemName: "hare.fill").font(.caption).foregroundStyle(Theme.text3)
            Text(String(format: "%.2gx", store.data.settings.figureSpeed))
                .font(.number(12, .semibold)).foregroundStyle(Theme.text2)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Top-down stickhandling

/// Bird's-eye view of the stick, blade and puck. The blade always cups the puck from the side it's pulling away from.
struct StickTopDownView: View {
    let exerciseID: String
    var color: Color
    var animate = true
    var speed = 1.0

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
            Canvas { ctx, size in draw(ctx, size, tl.date.timeIntervalSinceReferenceDate * speed) }
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
