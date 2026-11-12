import SwiftUI

/// Stylised front/back mannequin. Each block maps to a muscle (or nothing) and lights up by intensity.
struct BodyMapView: View {
    enum Side { case front, back }

    let side: Side
    let intensity: (Muscle) -> Double
    var color: Color = Theme.ice

    private struct Region {
        let muscle: Muscle?
        let rect: CGRect
        let corner: CGFloat
    }

    private static func r(_ m: Muscle?, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: CGFloat = 6) -> Region {
        Region(muscle: m, rect: CGRect(x: x, y: y, width: w, height: h), corner: c)
    }

    // 120 × 240 design space.
    private static let shared: [Region] = [
        r(nil, 47, 4, 26, 26, 13),   // head
        r(nil, 54, 29, 12, 8, 3),    // neck
        r(nil, 10, 113, 12, 14, 6),  // hands
        r(nil, 98, 113, 12, 14, 6),
        r(nil, 40, 214, 13, 14, 5),  // feet
        r(nil, 67, 214, 13, 14, 5),
    ]

    private static let front: [Region] = shared + [
        r(.shoulders, 26, 37, 20, 17, 9), r(.shoulders, 74, 37, 20, 17, 9),
        r(.chest, 46, 38, 14, 23, 6), r(.chest, 60, 38, 14, 23, 6),
        r(.biceps, 21, 55, 13, 27, 7), r(.biceps, 86, 55, 13, 27, 7),
        r(.forearms, 15, 83, 12, 29, 6), r(.forearms, 93, 83, 12, 29, 6),
        r(.abs, 48, 62, 24, 38, 6),
        r(.obliques, 39, 63, 9, 33, 5), r(.obliques, 72, 63, 9, 33, 5),
        r(.hipFlexors, 41, 98, 15, 13, 5), r(.hipFlexors, 64, 98, 15, 13, 5),
        r(.quads, 38, 112, 15, 54, 7), r(.quads, 67, 112, 15, 54, 7),
        r(.adductors, 53, 112, 7, 36, 3), r(.adductors, 60, 112, 7, 36, 3),
        r(nil, 40, 168, 12, 45, 6), r(nil, 68, 168, 12, 45, 6), // shins
    ]

    private static let back: [Region] = shared + [
        r(.shoulders, 26, 37, 20, 17, 9), r(.shoulders, 74, 37, 20, 17, 9),
        r(.upperBack, 46, 34, 28, 22, 6),
        r(.lats, 39, 56, 14, 30, 6), r(.lats, 67, 56, 14, 30, 6),
        r(.triceps, 21, 55, 13, 27, 7), r(.triceps, 86, 55, 13, 27, 7),
        r(.forearms, 15, 83, 12, 29, 6), r(.forearms, 93, 83, 12, 29, 6),
        r(.lowerBack, 53, 70, 14, 28, 5),
        r(.abductors, 35, 96, 6, 22, 3), r(.abductors, 79, 96, 6, 22, 3),
        r(.glutes, 41, 98, 19, 24, 9), r(.glutes, 60, 98, 19, 24, 9),
        r(.hamstrings, 38, 123, 15, 43, 7), r(.hamstrings, 67, 123, 15, 43, 7),
        r(.calves, 39, 168, 14, 38, 7), r(.calves, 67, 168, 14, 38, 7),
        r(nil, 41, 206, 11, 8, 3), r(nil, 68, 206, 11, 8, 3),
    ]

    var body: some View {
        let regions = side == .front ? Self.front : Self.back
        Canvas { ctx, size in
            let s = min(size.width / 120, size.height / 232)
            let ox = (size.width - 120 * s) / 2
            let oy = (size.height - 232 * s) / 2
            for region in regions {
                let rect = CGRect(x: ox + region.rect.minX * s, y: oy + region.rect.minY * s,
                                  width: region.rect.width * s, height: region.rect.height * s)
                    .insetBy(dx: 0.9, dy: 0.9)
                let path = Path(roundedRect: rect, cornerRadius: region.corner * s, style: .continuous)
                let v = region.muscle.map(intensity) ?? 0
                let fill = v > 0 ? color.opacity(0.22 + 0.78 * min(1, v)) : Color.white.opacity(0.07)
                ctx.fill(path, with: .color(fill))
            }
        }
        .aspectRatio(120 / 232, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct BodyMapPair: View {
    let intensity: (Muscle) -> Double
    var color: Color = Theme.ice

    var body: some View {
        HStack(spacing: 18) {
            VStack(spacing: 8) {
                BodyMapView(side: .front, intensity: intensity, color: color)
                Overline("Front", color: Theme.text3)
            }
            VStack(spacing: 8) {
                BodyMapView(side: .back, intensity: intensity, color: color)
                Overline("Back", color: Theme.text3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
