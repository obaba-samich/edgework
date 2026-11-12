import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    tiles
                    minutesChart
                    consistency
                    muscleHeat
                    categorySplit
                    achievements
                    history
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .screenBackground()
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { BenchmarksView() } label: { Image(systemName: "chart.line.uptrend.xyaxis") }
                }
            }
        }
    }

    // MARK: Tiles

    private var tiles: some View {
        let all = store.data.sessions
        let minutes = all.reduce(0) { $0 + $1.minutes }
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            StatTile(value: "\(store.currentStreak)", label: "Current streak", symbol: "flame.fill", color: Theme.amber)
            StatTile(value: "\(store.bestStreak)", label: "Best streak", symbol: "trophy.fill", color: Theme.amber)
            StatTile(value: "\(all.count)", label: "Workouts", symbol: "checkmark.seal.fill", color: Theme.green)
            StatTile(value: minutes >= 120 ? String(format: "%.1fh", Double(minutes) / 60) : "\(minutes)m", label: "Total time", symbol: "clock.fill", color: Theme.ice)
        }
    }

    // MARK: Minutes chart

    private struct DayMinutes: Identifiable {
        let date: Date
        let minutes: Int
        var id: Date { date }
    }

    private var minutesChart: some View {
        let today = Day.start(Date())
        let days: [DayMinutes] = (0..<14).reversed().map { back in
            let d = Day.add(-back, to: today)
            return DayMinutes(date: d, minutes: store.sessions(on: d).reduce(0) { $0 + $1.minutes })
        }
        let total = days.reduce(0) { $0 + $1.minutes }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Overline("Last 14 days")
                    Text("\(total) min").font(.number(28)).foregroundStyle(Theme.text)
                }
                Spacer()
                Text("avg \(total / 14) min/day").font(.caption.weight(.semibold)).foregroundStyle(Theme.text3)
            }
            Chart(days) { d in
                BarMark(x: .value("Day", d.date, unit: .day), y: .value("Minutes", d.minutes))
                    .foregroundStyle(Day.key(d.date) == Day.key(today) ? Theme.ice : Theme.ice.opacity(0.55))
                    .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        .foregroundStyle(Theme.text3)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Theme.stroke)
                    AxisValueLabel().foregroundStyle(Theme.text3)
                }
            }
            .frame(height: 160)
        }
        .cardStyle()
    }

    // MARK: Consistency grid

    private var consistency: some View {
        let weeks = 15
        let thisMonday = Day.week(of: Date())[0]
        let start = Day.add(-7 * (weeks - 1), to: thisMonday)
        var minutesByDay: [String: Int] = [:]
        for s in store.data.sessions { minutesByDay[Day.key(s.date), default: 0] += s.minutes }
        let todayKey = Day.key(Date())
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Overline("Consistency")
                Spacer()
                Text("\(weeks) weeks").font(.caption.weight(.semibold)).foregroundStyle(Theme.text3)
            }
            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 4) {
                    ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, l in
                        Text(l).font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.text3)
                            .frame(width: 10, height: 16)
                    }
                }
                ForEach(0..<weeks, id: \.self) { w in
                    VStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { d in
                            let date = Day.add(w * 7 + d, to: start)
                            let key = Day.key(date)
                            let m = minutesByDay[key] ?? 0
                            let future = date > Date()
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(future ? Color.clear : (m == 0 ? Color.white.opacity(0.06) : Theme.green.opacity(min(1, 0.3 + Double(m) / 60))))
                                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(key == todayKey ? Theme.ice : Color.clear, lineWidth: 1.5))
                                .frame(height: 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Muscle heat

    private var muscleHeat: some View {
        let volume = store.muscleVolume(days: 7)
        let top = max(1, volume.values.max() ?? 1)
        let ranked = volume.sorted { $0.value > $1.value }.prefix(4)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Overline("Muscles this week")
                Spacer()
                Text("by sets").font(.caption.weight(.semibold)).foregroundStyle(Theme.text3)
            }
            if volume.isEmpty {
                Text("Finish a workout to light up the map.").font(.subheadline).foregroundStyle(Theme.text2)
            }
            BodyMapPair(intensity: { (volume[$0] ?? 0) / top }, color: Theme.red)
                .frame(height: 220)
            if !ranked.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(ranked), id: \.key) { pair in
                        VStack(spacing: 2) {
                            Text("\(Int(pair.value.rounded()))").font(.number(16)).foregroundStyle(Theme.text)
                            Text(pair.key.title).font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.text2)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: Category split

    private var categorySplit: some View {
        var sets: [Category: Int] = [:]
        for s in store.sessions(inLast: 30) {
            for e in s.entries {
                if let c = Library.byID[e.exerciseID]?.category, c != .warmup { sets[c, default: 0] += e.sets }
            }
        }
        let ranked = sets.sorted { $0.value > $1.value }
        let top = max(1, ranked.first?.value ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Overline("Training mix")
                Spacer()
                Text("30 days").font(.caption.weight(.semibold)).foregroundStyle(Theme.text3)
            }
            if ranked.isEmpty {
                Text("Your mix of strength, speed, power and skills will show up here.").font(.subheadline).foregroundStyle(Theme.text2)
            }
            ForEach(ranked, id: \.key) { pair in
                HStack(spacing: 10) {
                    Image(systemName: pair.key.symbol).font(.system(size: 12, weight: .bold)).foregroundStyle(pair.key.color).frame(width: 18)
                    Text(pair.key.title).font(.subheadline).foregroundStyle(Theme.text).frame(width: 118, alignment: .leading)
                    GeometryReader { geo in
                        Capsule().fill(pair.key.color)
                            .frame(width: max(6, geo.size.width * CGFloat(pair.value) / CGFloat(top)))
                    }
                    .frame(height: 8)
                    Text("\(pair.value)").font(.number(13, .semibold)).foregroundStyle(Theme.text2).frame(width: 30, alignment: .trailing)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Achievements

    private var achievements: some View {
        let list = Achievements.all(store)
        let unlocked = list.filter(\.unlocked).count
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Achievements", subtitle: "\(unlocked) of \(list.count) unlocked")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(list) { a in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(a.unlocked ? Theme.amber.opacity(0.16) : Color.white.opacity(0.05))
                            Circle().trim(from: 0, to: a.progress)
                                .stroke(a.unlocked ? Theme.amber : Theme.text3, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Image(systemName: a.symbol)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(a.unlocked ? Theme.amber : Theme.text3)
                        }
                        .frame(width: 56, height: 56)
                        Text(a.title).font(.system(size: 13, weight: .bold)).foregroundStyle(a.unlocked ? Theme.text : Theme.text2)
                            .lineLimit(1).minimumScaleFactor(0.8)
                        Text(a.detail).font(.system(size: 11)).foregroundStyle(Theme.text3)
                            .multilineTextAlignment(.center).lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke))
                }
            }
        }
    }

    // MARK: History

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "History", subtitle: nil) {
                if !store.data.sessions.isEmpty {
                    NavigationLink("See all") { HistoryView() }
                        .font(.subheadline.weight(.bold))
                }
            }
            if store.data.sessions.isEmpty {
                EmptyState(symbol: "clock.arrow.circlepath", title: "No workouts yet", message: "Finish a workout and it'll show up here with your effort and notes.")
            } else {
                VStack(spacing: 10) {
                    ForEach(store.data.sessions.prefix(5)) { s in
                        NavigationLink { SessionDetailView(session: s) } label: { SessionRow(session: s) }
                            .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: session.focus.symbol, color: session.focus.color, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.title).font(.headline).foregroundStyle(Theme.text).lineLimit(1)
                Text(session.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                    .font(.footnote).foregroundStyle(Theme.text2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(session.minutes) min").font(.number(15)).foregroundStyle(Theme.text)
                Text("RPE \(session.rpe)").font(.caption.weight(.bold)).foregroundStyle(Theme.text3)
            }
        }
        .cardStyle(padding: 12)
    }
}

struct HistoryView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            ForEach(store.data.sessions) { s in
                NavigationLink { SessionDetailView(session: s) } label: {
                    HStack(spacing: 12) {
                        IconBadge(symbol: s.focus.symbol, color: s.focus.color, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                            Text(s.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(Theme.text2)
                        }
                        Spacer()
                        Text("\(s.minutes)m").font(.number(14)).foregroundStyle(Theme.text2)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .onDelete { idx in
                let ids = idx.map { store.data.sessions[$0].id }
                for id in ids { store.deleteSession(id) }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("History")
        .toolbar { EditButton() }
    }
}

struct SessionDetailView: View {
    @EnvironmentObject var store: Store
    let session: SessionRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Chip(text: session.focus.shortTitle, symbol: session.focus.symbol, color: session.focus.color)
                    Text(session.title).font(.display(30)).foregroundStyle(Theme.text)
                    Text(session.date.formatted(date: .complete, time: .shortened)).font(.subheadline).foregroundStyle(Theme.text2)
                }
                HStack(spacing: 10) {
                    StatTile(value: session.duration.clock, label: "Time", symbol: "stopwatch.fill", color: Theme.ice)
                    StatTile(value: "\(session.totalSets)", label: "Sets", symbol: "square.stack.fill", color: Theme.amber)
                    StatTile(value: "\(session.rpe)/10", label: "Effort", symbol: "flame.fill", color: Theme.red)
                }
                HStack {
                    Image(systemName: session.feeling.symbol)
                    Text(session.feeling.title)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.text2)

                if !session.note.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Overline("Notes")
                        Text(session.note).foregroundStyle(Theme.text)
                    }
                    .cardStyle()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Overline("Completed")
                    ForEach(Array(session.entries.enumerated()), id: \.offset) { _, e in
                        if let ex = Library.byID[e.exerciseID] {
                            NavigationLink { ExerciseDetailView(exercise: ex) } label: {
                                ExerciseRowLabel(exercise: ex, trailing: "\(e.sets)×\(e.measure.format(e.value))")
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .cardStyle(padding: 12)

                VStack(alignment: .leading, spacing: 10) {
                    Overline("Muscles hit")
                    BodyMapPair(intensity: { m in
                        session.entries.compactMap { Library.byID[$0.exerciseID] }.contains { $0.primary.contains(m) } ? 1 :
                            (session.entries.compactMap { Library.byID[$0.exerciseID] }.contains { $0.secondary.contains(m) } ? 0.35 : 0)
                    }, color: session.focus.color)
                    .frame(height: 200)
                }
                .cardStyle()
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Achievements

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let progress: Double
    var unlocked: Bool { progress >= 1 }
}

enum Achievements {
    @MainActor
    static func all(_ store: Store) -> [Achievement] {
        let n = store.data.sessions.count
        let best = store.bestStreak
        let minutes = store.data.sessions.reduce(0) { $0 + $1.minutes }
        let recovery = store.data.sessions.filter { $0.focus == .mobility || $0.focus == .recovery }.count
        let hands = store.data.sessions.filter { $0.focus == .hands }.count
        let tests = Set(store.data.benchmarks.map(\.benchmark)).count
        func p(_ v: Int, _ goal: Int) -> Double { min(1, Double(v) / Double(goal)) }
        return [
            Achievement(id: "first", title: "First Shift", detail: "Finish a workout", symbol: "flag.fill", progress: p(n, 1)),
            Achievement(id: "hat", title: "Hat Trick", detail: "3-day streak", symbol: "flame.fill", progress: p(best, 3)),
            Achievement(id: "week", title: "Full Week", detail: "7-day streak", symbol: "calendar", progress: p(best, 7)),
            Achievement(id: "iron", title: "Iron Man", detail: "21-day streak", symbol: "bolt.shield.fill", progress: p(best, 21)),
            Achievement(id: "ten", title: "Regular", detail: "10 workouts", symbol: "10.circle.fill", progress: p(n, 10)),
            Achievement(id: "25", title: "Veteran", detail: "25 workouts", symbol: "star.fill", progress: p(n, 25)),
            Achievement(id: "50", title: "Captain", detail: "50 workouts", symbol: "c.circle.fill", progress: p(n, 50)),
            Achievement(id: "100", title: "Hall of Fame", detail: "100 workouts", symbol: "trophy.fill", progress: p(n, 100)),
            Achievement(id: "icetime", title: "Ice Time", detail: "10 hours trained", symbol: "clock.fill", progress: p(minutes, 600)),
            Achievement(id: "recovery", title: "Recovery Pro", detail: "10 mobility days", symbol: "leaf.fill", progress: p(recovery, 10)),
            Achievement(id: "hands", title: "Soft Hands", detail: "10 hands sessions", symbol: "figure.hockey", progress: p(hands, 10)),
            Achievement(id: "combine", title: "Combine Ready", detail: "Log 4 different tests", symbol: "chart.line.uptrend.xyaxis", progress: p(tests, 4)),
        ]
    }
}
