import SwiftUI

/// "Which of these do you know?" Tap the moves you could do without looking them up.
/// Sets Exercises I know from your answers, and adds the specific moves you picked to your workouts.
struct KnowledgeQuiz: View {
    @EnvironmentObject var store: Store
    var accent: Color = Theme.ice
    @State private var sample: [Exercise] = []
    @State private var picked: Set<String> = []
    @State private var answered = false
    @State private var info: Exercise?

    /// Two moves from each level 2-9. Level 1 is stuff everyone knows, so it isn't tested.
    static let perLevel = 2

    /// A spread of moves from every level for your sport, from different categories where possible.
    static func makeSample(sport: Sport) -> [Exercise] {
        let other = sport == .track ? Category.hockeyOnly : Category.trackOnly
        var out: [Exercise] = []
        for lvl in 2...9 {
            var pool = Library.all.filter { Library.familiarity($0.id) == lvl && !other.contains($0.category) }.shuffled()
            var cats: Set<Category> = []
            for _ in 0..<perLevel {
                guard !pool.isEmpty else { break }
                let i = pool.firstIndex { !cats.contains($0.category) } ?? 0
                cats.insert(pool[i].category)
                out.append(pool.remove(at: i))
            }
        }
        return out.shuffled()
    }

    /// The highest level where you know at least one of its moves and at least half of everything up to it.
    static func level(picked: Set<String>, sample: [Exercise]) -> Int {
        var best = 1
        for lvl in 2...9 {
            let upTo = sample.filter { Library.familiarity($0.id) <= lvl }
            let here = sample.filter { Library.familiarity($0.id) == lvl }
            guard !here.isEmpty else { continue }
            let knownUpTo = Double(upTo.filter { picked.contains($0.id) }.count) / Double(upTo.count)
            if knownUpTo >= 0.5 && here.contains(where: { picked.contains($0.id) }) { best = lvl }
        }
        return best
    }

    private var level: Int { Self.level(picked: picked, sample: sample) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap every move you could do right now without looking it up. Tap ⓘ if you're not sure what one is.")
                .font(.subheadline).foregroundStyle(Theme.text2).fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(sample) { ex in tile(ex) }
            }

            HStack(spacing: 10) {
                Button {
                    picked = []
                    answered = true
                    apply()
                } label: { Text("Don't know any") }
                    .buttonStyle(SecondaryButtonStyle())
                Button {
                    sample = Self.makeSample(sport: store.data.settings.sport)
                    picked = []
                    answered = false
                } label: { Label("New set", systemImage: "arrow.clockwise") }
                    .buttonStyle(SecondaryButtonStyle())
            }

            if answered, let k = Knowledge(rawValue: level) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You know \(picked.count) of \(sample.count)").font(.headline).foregroundStyle(Theme.text)
                    Text("Your workouts will use **\(k.section.title) · \(k.step). \(k.title)** (level \(k.rawValue) of 9)\(extraText). \(k.detail)")
                        .font(.footnote).foregroundStyle(Theme.text2).fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accent.opacity(0.12)))
            }
        }
        .onAppear { if sample.isEmpty { sample = Self.makeSample(sport: store.data.settings.sport) } }
        .sheet(item: $info) { ex in
            NavigationStack { ExerciseDetailView(exercise: ex) }.environmentObject(store)
        }
    }

    /// Specialised moves you picked come along even when your level doesn't cover them.
    private var extraText: String {
        let extra = sample.filter { picked.contains($0.id) && Library.familiarity($0.id) > level }.count
        return extra == 0 ? "" : ", plus the \(extra) other move\(extra == 1 ? "" : "s") you picked"
    }

    private func tile(_ ex: Exercise) -> some View {
        let on = picked.contains(ex.id)
        return Button {
            if on { picked.remove(ex.id) } else { picked.insert(ex.id) }
            answered = true
            apply()
            store.haptic(.light)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: ex.symbol).font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: on ? "checkmark.circle.fill" : "circle")
                }
                Text(ex.name).font(.system(size: 14, weight: .semibold)).lineLimit(2).multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)
            }
            .foregroundStyle(on ? Theme.bg : Theme.text)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(on ? accent : Theme.surface))
        }
        .buttonStyle(PressableStyle())
        .overlay(alignment: .bottomTrailing) {
            Button { info = ex } label: {
                Image(systemName: "info.circle").font(.system(size: 15)).padding(10)
                    .foregroundStyle(on ? Theme.bg.opacity(0.8) : Theme.text3)
            }
        }
    }

    private func apply() {
        store.data.settings.knowledgeLevel = level
        for ex in sample {
            // Moves your level already covers don't need to be in Learned.
            if picked.contains(ex.id) && Library.familiarity(ex.id) > level {
                store.data.settings.learned.insert(ex.id)
            } else {
                store.data.settings.learned.remove(ex.id)
            }
        }
    }
}

/// The quiz on its own screen, from Settings.
struct KnowledgeQuizScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Overline("Exercises I know", color: Theme.ice)
                Text("Which of these do you know?").font(.display(30)).foregroundStyle(Theme.text)
                KnowledgeQuiz()
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("Quick test")
        .navigationBarTitleDisplayMode(.inline)
    }
}
