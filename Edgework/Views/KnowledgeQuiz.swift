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

    static let perTier = 8

    /// A spread of practice/gym moves and specialised ones for your sport, one per category where possible.
    static func makeSample(sport: Sport) -> [Exercise] {
        let other = sport == .track ? Category.hockeyOnly : Category.trackOnly
        func pick(_ tier: Int) -> [Exercise] {
            let pool = Library.all.filter { Library.familiarity($0.id) == tier && !other.contains($0.category) }.shuffled()
            var byCat: [Category: [Exercise]] = [:]
            for ex in pool { byCat[ex.category, default: []].append(ex) }
            var out: [Exercise] = []
            var cats = byCat.keys.shuffled()
            while out.count < perTier, !cats.isEmpty {
                cats = cats.filter { !(byCat[$0] ?? []).isEmpty }
                for c in cats where out.count < perTier { out.append(byCat[c]!.removeFirst()) }
            }
            return out
        }
        return (pick(2) + pick(3)).shuffled()
    }

    /// Know most of the practice moves → that level; also know most of the specialised ones → everything.
    static func level(picked: Set<String>, sample: [Exercise]) -> Int {
        let common = sample.filter { Library.familiarity($0.id) == 2 }
        let special = sample.filter { Library.familiarity($0.id) == 3 }
        let c = Double(common.filter { picked.contains($0.id) }.count) / Double(max(1, common.count))
        let s = Double(special.filter { picked.contains($0.id) }.count) / Double(max(1, special.count))
        if c >= 0.6 && s >= 0.6 { return 3 }
        if c >= 0.5 { return 2 }
        return 1
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
                    Text("Your workouts will use **\(k.title)**\(extraText). \(k.detail)")
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
        store.data.settings.knowledge = level
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
