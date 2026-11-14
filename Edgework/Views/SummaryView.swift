import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var store: Store
    @ObservedObject var engine: PlayerEngine
    let onClose: () -> Void

    @State private var rpe = 6
    @State private var feeling = Feeling.right
    @State private var note = ""
    @State private var appeared = false
    @State private var sharing = false
    @FocusState private var noteFocused: Bool

    private var setsDone: Int { engine.completed.values.reduce(0, +) }
    private var exercisesDone: Int { engine.completed.values.filter { $0 > 0 }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Theme.green.opacity(0.14)).frame(width: 110, height: 110)
                            .scaleEffect(appeared ? 1 : 0.4)
                        Image(systemName: "checkmark")
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(Theme.green)
                            .scaleEffect(appeared ? 1 : 0.2)
                    }
                    Text("Workout complete").font(.display(34)).foregroundStyle(Theme.text)
                    Text(engine.workout.title).font(.subheadline).foregroundStyle(Theme.text2)
                }
                .padding(.top, 30)

                HStack(spacing: 10) {
                    StatTile(value: engine.elapsed.clock, label: "Time", symbol: "stopwatch.fill", color: Theme.ice)
                    StatTile(value: "\(setsDone)", label: "Sets", symbol: "square.stack.fill", color: Theme.amber)
                    StatTile(value: "\(exercisesDone)", label: "Exercises", symbol: "list.bullet", color: Theme.green)
                }

                Button { sharing = true } label: { Label("Share card", systemImage: "square.and.arrow.up") }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.ice))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Overline("Effort (RPE)")
                        Spacer()
                        Text(rpeLabel).font(.subheadline.weight(.semibold)).foregroundStyle(rpeColor(rpe))
                    }
                    HStack(spacing: 5) {
                        ForEach(1...10, id: \.self) { v in
                            Button { rpe = v; store.haptic(.light) } label: {
                                Text("\(v)")
                                    .font(.number(15))
                                    .foregroundStyle(v == rpe ? Theme.bg : Theme.text)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(v <= rpe ? rpeColor(v).opacity(v == rpe ? 1 : 0.3) : Theme.surface2))
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Overline("How was the difficulty?")
                    HStack(spacing: 8) {
                        ForEach(Feeling.allCases, id: \.self) { f in
                            Button { feeling = f; store.haptic(.light) } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: f.symbol).font(.system(size: 22, weight: .semibold))
                                    Text(f.title).font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(feeling == f ? Theme.bg : Theme.text)
                                .frame(maxWidth: .infinity)
                                .frame(height: 74)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(feeling == f ? feelingColor(f) : Theme.surface2))
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                    Text(feelingHint).font(.caption).foregroundStyle(Theme.text3)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Overline("Notes")
                    TextField("How did the legs feel? Anything hurt?", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                        .focused($noteFocused)
                        .foregroundStyle(Theme.text)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface2))
                }
                .cardStyle()

                Button {
                    store.log(engine.record(rpe: rpe, feeling: feeling, note: note))
                    onClose()
                } label: {
                    Label("Save workout", systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.green))

                Button("Discard", role: .destructive) { onClose() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.red)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $sharing) { ShareCardSheet(title: engine.workout.title, card: card) }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) { appeared = true } }
    }

    private func card(_ fmt: ShareFormat) -> ShareCard {
        let names = engine.workout.ordered
            .filter { ($0.block == .main || $0.block == .finisher || $0.block == .musts) && (engine.completed[$0.id] ?? 0) > 0 }
            .compactMap { $0.exercise?.name }
        var stats = [ShareStat(value: engine.elapsed.clock, label: "Time"),
                     ShareStat(value: "\(setsDone)", label: "Sets"),
                     ShareStat(value: "\(exercisesDone)", label: "Exercises")]
        let shots = engine.workout.items.reduce(0) { n, it in
            ShotType.exerciseMap[it.exerciseID] != nil ? n + (engine.completed[it.id] ?? 0) * store.target(it) : n
        }
        if shots > 0 { stats.append(ShareStat(value: "\(shots)", label: "Shots")) }
        return ShareCard(overline: "Workout complete", title: engine.workout.title,
                         subtitle: names.prefix(fmt == .story ? 6 : 3).joined(separator: " · "),
                         symbol: engine.workout.focus.symbol, accent: engine.workout.focus.color,
                         stats: stats, streak: store.streakIncludingToday(pending: true), format: fmt)
    }

    private var rpeLabel: String {
        switch rpe {
        case 1...3: "Easy"
        case 4...5: "Moderate"
        case 6...7: "Hard"
        case 8...9: "Very hard"
        default: "Max"
        }
    }

    private func rpeColor(_ v: Int) -> Color {
        switch v {
        case 1...3: Theme.green
        case 4...6: Theme.ice
        case 7...8: Theme.amber
        default: Theme.red
        }
    }

    private func feelingColor(_ f: Feeling) -> Color {
        switch f {
        case .easy: Theme.amber
        case .right: Theme.green
        case .hard: Theme.ice
        }
    }

    private var feelingHint: String {
        let pct = Int((store.intensity * 100).rounded())
        switch feeling {
        case .easy: return "Global intensity goes up 5% (\(pct)% → \(pct + 5)%)."
        case .hard: return "Global intensity goes down 5% (\(pct)% → \(max(40, pct - 5))%)."
        case .right: return "Intensity stays at \(pct)%."
        }
    }
}
