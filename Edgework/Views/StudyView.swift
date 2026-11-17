import SwiftUI

/// Learn exercises outside your knowledge setting, one card at a time. "Got it" adds the move to your workouts.
struct StudyView: View {
    @EnvironmentObject var store: Store
    @State private var skipped: Set<String> = []
    @State private var showSteps = false
    @State private var category: Category?
    /// Only the level right above yours, so you can work through it and move up.
    @State private var nextOnly = true

    private var settings: Settings { store.data.settings }

    /// The level right above your Exercises I know setting, if there is one.
    private var nextLevel: Knowledge? { Knowledge(rawValue: settings.knowledgeLevel + 1) }

    private var queue: [Exercise] {
        let all = fullQueue
        guard nextOnly, let next = nextLevel else { return all }
        return all.filter { Library.familiarity($0.id) == next.rawValue }
    }

    /// Everything you don't know yet for your sport and equipment, easiest-to-know first.
    private var fullQueue: [Exercise] {
        let other = settings.sport == .track ? Category.hockeyOnly : Category.trackOnly
        return Library.all
            .filter { !settings.isFamiliar($0) && !settings.excluded.contains($0.id) && !other.contains($0.category) }
            .filter { $0.equipment.allSatisfy { settings.equipment.contains($0) } }
            .filter { category == nil || $0.category == category }
            .sorted { (Library.familiarity($0.id), $0.level, $0.name) < (Library.familiarity($1.id), $1.level, $1.name) }
    }

    private var current: Exercise? { queue.first { !skipped.contains($0.id) } ?? queue.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("Study", color: Theme.ice)
                    Text("Learn new exercises").font(.display(32)).foregroundStyle(Theme.text)
                    Text("Read it, watch a demo, try it. Tap Got it and it starts showing up in your workouts.")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                }

                HStack(spacing: 10) {
                    StatTile(value: "\(settings.learned.count)", label: "Learned", symbol: "graduationcap.fill", color: Theme.green)
                    StatTile(value: "\(queue.count)", label: "To learn", symbol: "book.fill", color: Theme.ice)
                }

                if settings.knowledgeLevel == 9 {
                    Text("Your workouts already use every exercise. Set Settings › Difficulty & exercises › Exercises I know to a lower level to study the rest one at a time.")
                        .font(.footnote).foregroundStyle(Theme.text2).cardStyle()
                }

                if let next = nextLevel { nextLevelCard(next) }

                categoryFilter

                if let ex = current {
                    card(ex)
                } else if nextOnly, category == nil, let next = nextLevel {
                    moveUpCard(next)
                } else {
                    EmptyState(symbol: "checkmark.seal.fill", title: "Nothing left to learn",
                               message: category == nil ? "You know every exercise for your equipment." : "Pick another category.")
                }

                if !settings.learned.isEmpty {
                    NavigationLink { LearnedList() } label: {
                        Label("Learned exercises (\(settings.learned.count))", systemImage: "list.bullet")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func nextLevelCard(_ next: Knowledge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $nextOnly.animation()) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Study the next level").font(.headline).foregroundStyle(Theme.text)
                    Text("Level \(next.rawValue) of 9: \(next.fullTitle)").font(.caption).foregroundStyle(Theme.text2)
                }
            }
            .tint(Theme.ice)
            if nextOnly {
                let left = queue.count
                Text(left == 0 ? "All done. Move up when you're ready." : "\(left) move\(left == 1 ? "" : "s") left in this level. Learn them all and you can move up.")
                    .font(.footnote).foregroundStyle(Theme.text2)
            }
        }
        .cardStyle()
    }

    /// Shown when you've learned every move in the next level.
    private func moveUpCard(_ next: Knowledge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("You know all of \(next.title)", systemImage: "arrow.up.circle.fill")
                .font(.headline).foregroundStyle(Theme.green)
            Text("Move your Exercises I know setting up to level \(next.rawValue), \(next.fullTitle). Your workouts start using every move in it.")
                .font(.subheadline).foregroundStyle(Theme.text2)
            Button {
                withAnimation {
                    // Those moves are covered by the level now, so they don't need to stay in Learned.
                    let ids = Set(Library.familiarityLevels[next.rawValue - 1])
                    store.data.settings.learned.subtract(ids)
                    store.data.settings.knowledgeLevel = next.rawValue
                    skipped = []
                    category = nil
                }
                store.notify(.success)
            } label: { Label("Move up to level \(next.rawValue)", systemImage: "arrow.up") }
                .buttonStyle(PrimaryButtonStyle(color: Theme.green))
        }
        .cardStyle()
    }

    private var categoryFilter: some View {
        let cats = Array(Set(Library.all.filter { ex in !settings.isFamiliar(ex) && (!nextOnly || nextLevel.map { Library.familiarity(ex.id) == $0.rawValue } ?? true) }.map(\.category)))
            .filter { !(settings.sport == .track ? Category.hockeyOnly : Category.trackOnly).contains($0) }
            .sorted { $0.title < $1.title }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { category = nil } label: { Chip(text: "All", color: Theme.ice, filled: category == nil) }
                ForEach(cats) { c in
                    Button { category = c; skipped = [] } label: { Chip(text: c.title, symbol: c.symbol, color: c.color, filled: category == c) }
                }
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }

    private func card(_ ex: Exercise) -> some View {
        let color = ex.category.color
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                IconBadge(symbol: ex.symbol, color: color, size: 54)
                VStack(alignment: .leading, spacing: 3) {
                    Text(ex.name).font(.display(26)).foregroundStyle(Theme.text)
                    Text("\(ex.category.title) · Level \(Library.familiarity(ex.id)) · \((Knowledge(rawValue: Library.familiarity(ex.id)) ?? .everything).fullTitle)")
                        .font(.caption.weight(.semibold)).foregroundStyle(color)
                }
            }
            Text(ex.summary).font(.body).foregroundStyle(Theme.text)

            if showSteps {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(ex.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)").font(.number(13)).foregroundStyle(Theme.bg)
                                .frame(width: 22, height: 22).background(Circle().fill(color))
                            Text(step).font(.subheadline).foregroundStyle(Theme.text)
                        }
                    }
                    if !ex.cues.isEmpty {
                        Text(ex.cues.joined(separator: " · ")).font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
                    }
                    Text(ex.why).font(.caption).foregroundStyle(Theme.text3)
                }
            } else {
                Button { withAnimation { showSteps = true } } label: { Label("Show how to do it", systemImage: "list.number") }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(color)
            }

            DemoVideoLink(exercise: ex, color: color)

            HStack(spacing: 10) {
                Button {
                    store.start(Workout(title: ex.name, subtitle: "Practice", focus: .custom, items: [store.item(for: ex, block: .main)]))
                } label: { Label("Try it", systemImage: "play.fill") }
                    .buttonStyle(SecondaryButtonStyle(color: color))
                Button {
                    withAnimation {
                        skipped.insert(ex.id)
                        showSteps = false
                    }
                } label: { Text("Later") }
                    .buttonStyle(SecondaryButtonStyle())
            }
            Button {
                withAnimation {
                    store.data.settings.learned.insert(ex.id)
                    showSteps = false
                }
                store.haptic(.light)
            } label: { Label("I already know this one", systemImage: "hand.thumbsup.fill") }
                .buttonStyle(SecondaryButtonStyle(color: Theme.green))
            Button {
                withAnimation {
                    store.data.settings.learned.insert(ex.id)
                    showSteps = false
                }
                store.notify(.success)
            } label: { Label("Got it, add to my workouts", systemImage: "checkmark") }
                .buttonStyle(PrimaryButtonStyle(color: Theme.green))
        }
        .cardStyle()
        .id(ex.id)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }
}

struct LearnedList: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            ForEach(Library.all.filter { store.data.settings.learned.contains($0.id) }) { ex in
                NavigationLink { ExerciseDetailView(exercise: ex) } label: { ExerciseRowLabel(exercise: ex) }
                    .swipeActions {
                        Button("Forget", role: .destructive) { store.data.settings.learned.remove(ex.id) }
                    }
                    .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Learned")
    }
}
