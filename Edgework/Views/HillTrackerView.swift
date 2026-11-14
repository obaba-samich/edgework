import SwiftUI

/// Tap at the bottom, the top and the bottom again. Times every climb and shows how your uphill speed changes.
struct HillTrackerPanel: View {
    @EnvironmentObject var store: Store
    let exercise: Exercise
    let target: Int

    enum Leg { case ready, up, down }

    @State private var leg = Leg.ready
    @State private var legStart = Date()
    @State private var climbs: [Double] = []
    @State private var descents: [Double] = []
    @State private var previous: [Double] = []

    private var color: Color { exercise.category.color }

    var body: some View {
        VStack(spacing: 12) {
            TimelineView(.periodic(from: .now, by: 0.1)) { tl in
                let t = leg == .ready ? 0 : tl.date.timeIntervalSince(legStart)
                Button(action: tap) {
                    VStack(spacing: 4) {
                        Text(title).font(.headline)
                        Text(leg == .ready ? "Trip \(min(climbs.count + 1, target)) of \(target)" : Self.clock(t))
                            .font(.number(40, .heavy)).monospacedDigit()
                        Text(subtitle).font(.caption.weight(.semibold)).opacity(0.8)
                    }
                    .foregroundStyle(leg == .up ? Theme.bg : Theme.text)
                    .frame(maxWidth: .infinity).frame(height: 130)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(leg == .up ? color : (leg == .down ? Theme.surface2 : color.opacity(0.2))))
                }
                .buttonStyle(PressableStyle())
            }

            if !climbs.isEmpty { splits }
        }
        .onAppear {
            previous = store.data.hillClimbs[exercise.id] ?? []
            if UserDefaults.standard.string(forKey: "autoStartExercise") != nil {   // screenshot demo
                climbs = [40.8, 42.3, 44.0]; descents = [35.1, 33.9, 34.6]; leg = .up; legStart = Date().addingTimeInterval(-21.4)
            }
        }
        .onDisappear(perform: save)
    }

    private var title: String {
        switch leg {
        case .ready: climbs.count >= target ? "All trips done" : "Tap to start the climb"
        case .up: "Going up · tap at the top"
        case .down: "Coming down · tap at the bottom"
        }
    }

    private var subtitle: String {
        switch leg {
        case .ready: climbs.count >= target ? "Tap to add an extra trip" : "Up = endurance. Steady effort."
        case .up: "Short steps, lean from the ankles"
        case .down: "Catch yourself: short quick steps, soft landings"
        }
    }

    private var splits: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Overline("Climb times")
                Spacer()
                if let first = climbs.first, let last = climbs.last, climbs.count > 1 {
                    let pct = (last - first) / first * 100
                    Text(pct > 0.5 ? String(format: "%.0f%% slower than trip 1", pct) : (pct < -0.5 ? String(format: "%.0f%% faster than trip 1", -pct) : "Holding pace"))
                        .font(.caption.weight(.bold)).foregroundStyle(pct > 5 ? Theme.amber : Theme.green)
                }
            }
            ForEach(Array(climbs.enumerated()), id: \.offset) { i, c in
                HStack(spacing: 10) {
                    Text("\(i + 1)").font(.number(13)).foregroundStyle(Theme.bg)
                        .frame(width: 22, height: 22).background(Circle().fill(color))
                    Text("Up \(Self.clock(c))").font(.number(15)).foregroundStyle(Theme.text)
                    if i < descents.count {
                        Text("down \(Self.clock(descents[i]))").font(.caption).foregroundStyle(Theme.text3)
                    }
                    Spacer()
                    if i > 0 { delta(c - climbs[i - 1]) }
                }
            }
            if !previous.isEmpty {
                let avgNow = climbs.reduce(0, +) / Double(climbs.count)
                let avgThen = previous.reduce(0, +) / Double(previous.count)
                HStack {
                    Text("Avg climb \(Self.clock(avgNow)) · last time \(Self.clock(avgThen))").font(.caption).foregroundStyle(Theme.text2)
                    Spacer()
                    delta(avgNow - avgThen)
                }
                .padding(.top, 4)
            }
        }
        .cardStyle(padding: 12)
    }

    /// Faster (negative) is green.
    private func delta(_ d: Double) -> some View {
        Text(String(format: "%@%.1f s", d > 0 ? "+" : "−", abs(d)))
            .font(.number(13)).foregroundStyle(abs(d) < 0.3 ? Theme.text2 : (d < 0 ? Theme.green : Theme.amber))
    }

    private func tap() {
        let now = Date()
        switch leg {
        case .ready:
            leg = .up
        case .up:
            climbs.append(now.timeIntervalSince(legStart))
            leg = .down
            store.notify(.success)
        case .down:
            descents.append(now.timeIntervalSince(legStart))
            leg = .ready
            if climbs.count >= target { store.notify(.success) }
        }
        legStart = now
        store.haptic(.medium)
    }

    private func save() {
        guard !climbs.isEmpty else { return }
        store.data.hillClimbs[exercise.id] = climbs
    }

    static func clock(_ t: Double) -> String {
        let s = max(0, t)
        return s >= 60 ? String(format: "%d:%04.1f", Int(s) / 60, s.truncatingRemainder(dividingBy: 60)) : String(format: "%.1f s", s)
    }
}
