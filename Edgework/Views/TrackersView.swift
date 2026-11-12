import SwiftUI
import Charts

// MARK: - Daily goals on Today

struct DailyGoalsCard: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let log = store.daily()
        let st = store.data.settings
        VStack(alignment: .leading, spacing: 12) {
            Overline("Daily goals")
            HStack(spacing: 8) {
                NavigationLink { ShotTrackerView() } label: {
                    goal("\(log.totalShots)", "/\(st.shotGoal) shots", Double(log.totalShots) / Double(max(1, st.shotGoal)), Color(hex: 0xB8F36B), "scope")
                }
                NavigationLink { StickhandlingView() } label: {
                    goal("\(log.stickMinutes)", "/\(st.stickGoal) min hands", Double(log.stickMinutes) / Double(max(1, st.stickGoal)), Color(hex: 0xF5D76E), "figure.hockey")
                }
                Button {
                    store.updateDaily { $0.water += 1 }
                    store.haptic(.light)
                } label: {
                    goal("\(log.water)", "/\(st.waterGoal) water", Double(log.water) / Double(max(1, st.waterGoal)), Theme.ice, "drop.fill")
                }
                NavigationLink { RunLogView() } label: {
                    let km = store.weekRunKm
                    goal(store.distanceText(km).components(separatedBy: " ").first ?? "0", "/\(store.distanceText(st.runGoalKm)) wk",
                         km / max(0.1, st.runGoalKm), Color(hex: 0x22D3EE), "figure.run")
                }
            }
            .buttonStyle(PressableStyle())
        }
        .cardStyle()
    }

    private func goal(_ value: String, _ label: String, _ progress: Double, _ color: Color, _ symbol: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Ring(progress: progress, color: color, lineWidth: 6)
                if progress >= 1 {
                    Image(systemName: "checkmark").font(.system(size: 16, weight: .heavy)).foregroundStyle(color)
                } else {
                    Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(color)
                }
            }
            .frame(width: 52, height: 52)
            Text(value).font(.number(16)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.text2).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shot tracker

struct ShotTrackerView: View {
    @EnvironmentObject var store: Store
    @State private var date = Date()

    private struct DayShots: Identifiable {
        let date: Date
        let type: ShotType
        let count: Int
        var id: String { Day.key(date) + type.rawValue }
    }

    var body: some View {
        let log = store.daily(date)
        let goal = store.data.settings.shotGoal
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Overline(Day.key(date) == Day.key(Date()) ? "Today" : date.formatted(.dateTime.weekday(.wide).month().day()), color: Color(hex: 0xB8F36B))
                    Text("Shot Tracker").font(.display(32)).foregroundStyle(Theme.text)
                }
                HStack(spacing: 18) {
                    ZStack {
                        Ring(progress: Double(log.totalShots) / Double(max(1, goal)), color: Color(hex: 0xB8F36B), lineWidth: 14)
                        VStack(spacing: 0) {
                            Text("\(log.totalShots)").font(.number(40, .heavy)).foregroundStyle(Theme.text)
                                .contentTransition(.numericText())
                            Text("of \(goal)").font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
                        }
                    }
                    .frame(width: 150, height: 150)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(ShotType.allCases) { t in
                            HStack {
                                Circle().fill(t.color).frame(width: 8, height: 8)
                                Text(t.title).font(.subheadline).foregroundStyle(Theme.text2)
                                Spacer()
                                Text("\(log.shots(t))").font(.number(14)).foregroundStyle(Theme.text)
                            }
                        }
                        if log.totalShots > 0 {
                            Text("On target: \(log.onTarget) (\(Int(Double(log.onTarget) / Double(max(1, log.totalShots)) * 100))%)")
                                .font(.caption.weight(.semibold)).foregroundStyle(Theme.green)
                        }
                    }
                }
                .cardStyle()

                VStack(spacing: 0) {
                    ForEach(ShotType.allCases) { t in
                        HStack(spacing: 8) {
                            Text(t.title).font(.headline).foregroundStyle(Theme.text).frame(width: 92, alignment: .leading)
                            Button { store.addShots(t, -5, date: date) } label: { Text("−5") }.buttonStyle(MiniPillStyle(color: Theme.text2))
                            Spacer()
                            ForEach([1, 10, 25], id: \.self) { n in
                                Button { withAnimation { store.addShots(t, n, date: date) } } label: { Text("+\(n)") }
                                    .buttonStyle(MiniPillStyle(color: t.color))
                            }
                        }
                        .padding(.vertical, 8)
                        if t != ShotType.allCases.last { Divider().overlay(Theme.stroke) }
                    }
                }
                .cardStyle(padding: 14)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("On target").font(.headline).foregroundStyle(Theme.text)
                        Text("Hit the net, a corner or your target").font(.caption).foregroundStyle(Theme.text2)
                    }
                    Spacer()
                    TargetStepper(value: "\(log.onTarget)", tint: Theme.green,
                                  minus: { store.updateDaily(date) { $0.onTarget = max(0, $0.onTarget - 1) } },
                                  plus: { store.updateDaily(date) { $0.onTarget += 1 } })
                }
                .cardStyle(padding: 14)

                NavigationLink { PuckCounterView() } label: {
                    Label("Shoot a bucket with the Puck Counter", systemImage: "circle.grid.3x3.fill")
                }
                .buttonStyle(SecondaryButtonStyle(color: Color(hex: 0xB8F36B)))

                chart

                Text("Shooting exercises you finish in workouts (wrist, snap, slap, backhand, catch & release) count automatically.")
                    .font(.caption).foregroundStyle(Theme.text3)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chart: some View {
        let days: [DayShots] = (0..<14).reversed().flatMap { back -> [DayShots] in
            let d = Day.add(-back, to: Day.start(Date()))
            let log = store.daily(d)
            return ShotType.allCases.map { DayShots(date: d, type: $0, count: log.shots($0)) }
        }
        return VStack(alignment: .leading, spacing: 10) {
            Overline("Last 14 days")
            Chart(days) { d in
                BarMark(x: .value("Day", d.date, unit: .day), y: .value("Shots", d.count))
                    .foregroundStyle(d.type.color)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true).foregroundStyle(Theme.text3)
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
}

// MARK: - Stickhandling

struct StickhandlingView: View {
    @EnvironmentObject var store: Store
    @State private var startedAt: Date?

    var body: some View {
        let log = store.daily()
        let goal = store.data.settings.stickGoal
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Stickhandling").font(.display(32)).foregroundStyle(Theme.text)
                HStack(spacing: 18) {
                    ZStack {
                        Ring(progress: Double(log.stickMinutes) / Double(max(1, goal)), color: Color(hex: 0xF5D76E), lineWidth: 14)
                        VStack(spacing: 0) {
                            Text("\(log.stickMinutes)").font(.number(40, .heavy)).foregroundStyle(Theme.text)
                            Text("of \(goal) min").font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
                        }
                    }
                    .frame(width: 150, height: 150)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach([5, 10, 15], id: \.self) { m in
                            Button { store.updateDaily { $0.stickMinutes += m }; store.haptic(.light) } label: { Text("+\(m) min") }
                                .buttonStyle(MiniPillStyle(color: Color(hex: 0xF5D76E)))
                        }
                        Button { store.updateDaily { $0.stickMinutes = max(0, $0.stickMinutes - 5) } } label: { Text("−5 min") }
                            .buttonStyle(MiniPillStyle(color: Theme.text2))
                    }
                }
                .cardStyle()

                TimelineView(.periodic(from: .now, by: 1)) { tl in
                    let elapsed = startedAt.map { Int(tl.date.timeIntervalSince($0)) } ?? 0
                    VStack(spacing: 12) {
                        Text(elapsed.clock).font(.number(56, .heavy)).foregroundStyle(Theme.text)
                        Button {
                            if let s = startedAt {
                                let minutes = max(1, Int((Date().timeIntervalSince(s) / 60).rounded()))
                                store.updateDaily { $0.stickMinutes += minutes }
                                store.notify(.success)
                                startedAt = nil
                            } else {
                                startedAt = Date()
                                UIApplication.shared.isIdleTimerDisabled = true
                            }
                        } label: {
                            Label(startedAt == nil ? "Start session timer" : "Stop & log", systemImage: startedAt == nil ? "play.fill" : "stop.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle(color: startedAt == nil ? Color(hex: 0xF5D76E) : Theme.red))
                    }
                    .frame(maxWidth: .infinity)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Overline("Drill ideas")
                    ForEach(Library.all.filter { $0.category == .stickhandling }) { ex in
                        NavigationLink { ExerciseDetailView(exercise: ex) } label: {
                            ExerciseRowLabel(exercise: ex, trailing: ex.defaultTarget()).padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle(padding: 12)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

// MARK: - Runs

struct RunLogView: View {
    @EnvironmentObject var store: Store
    @State private var logging = false

    var body: some View {
        let week = Day.week(of: Date())
        let goal = store.data.settings.runGoalKm
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Running").font(.display(32)).foregroundStyle(Theme.text)
                HStack(spacing: 18) {
                    ZStack {
                        Ring(progress: store.weekRunKm / max(0.1, goal), color: Color(hex: 0x22D3EE), lineWidth: 14)
                        VStack(spacing: 0) {
                            Text(store.distanceText(store.weekRunKm)).font(.number(26, .heavy)).foregroundStyle(Theme.text)
                            Text("of \(store.distanceText(goal))").font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
                        }
                    }
                    .frame(width: 150, height: 150)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(week, id: \.self) { d in
                            HStack {
                                Text(d.formatted(.dateTime.weekday(.abbreviated))).font(.caption.weight(.bold)).foregroundStyle(Theme.text2).frame(width: 34, alignment: .leading)
                                let km = store.daily(d).runKm
                                Text(km > 0 ? store.distanceText(km) : "—").font(.number(13)).foregroundStyle(km > 0 ? Theme.text : Theme.text3)
                            }
                        }
                    }
                }
                .cardStyle()
                Button { logging = true } label: { Label("Log a run", systemImage: "plus") }
                    .buttonStyle(PrimaryButtonStyle(color: Color(hex: 0x22D3EE)))
                VStack(alignment: .leading, spacing: 10) {
                    Overline("Run workouts")
                    ForEach(Library.all.filter { $0.category == .running }) { ex in
                        NavigationLink { ExerciseDetailView(exercise: ex) } label: {
                            ExerciseRowLabel(exercise: ex, trailing: ex.defaultTarget()).padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle(padding: 12)
                Text("Runs from workouts and logged runs count toward your weekly goal. Change it in Profile → Goals.")
                    .font(.caption).foregroundStyle(Theme.text3)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $logging) { ManualLogView().environmentObject(store) }
    }
}

// MARK: - Readiness

struct ReadinessCard: View {
    @EnvironmentObject var store: Store
    @State private var checkingIn = false

    var body: some View {
        let log = store.daily()
        Group {
            if let score = log.readiness {
                let color = score >= 75 ? Theme.green : (score >= 55 ? Theme.amber : Theme.red)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Ring(progress: Double(score) / 100, color: color, lineWidth: 7)
                            Text("\(score)").font(.number(20)).foregroundStyle(Theme.text)
                        }
                        .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 3) {
                            Overline("Readiness", color: color)
                            Text(score >= 75 ? "Good to go. Push it today." : (score >= 55 ? "Okay. Train, but listen to your body." : "Run down. Go lighter or recover."))
                                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                            Text("Sleep \(String(format: "%.1f", log.sleep ?? 0))h · soreness \(log.soreness ?? 0)/5 · energy \(log.energy ?? 0)/5")
                                .font(.caption).foregroundStyle(Theme.text2)
                        }
                        Spacer(minLength: 0)
                    }
                    if score < 55 {
                        HStack(spacing: 8) {
                            Button {
                                store.data.dayScale[Day.key(Date())] = store.todayScale < 1 ? nil : 0.85
                            } label: { Text(store.todayScale < 1 ? "Undo lighter day" : "Lighten today −15%") }
                                .buttonStyle(MiniPillStyle(color: Theme.ice))
                            Button { store.setTodayFocus(.recovery) } label: { Text("Switch to recovery") }
                                .buttonStyle(MiniPillStyle(color: Theme.green))
                        }
                    }
                    Button("Edit check-in") { checkingIn = true }.font(.caption.weight(.bold)).foregroundStyle(Theme.text2)
                }
                .cardStyle()
            } else {
                Button { checkingIn = true } label: {
                    HStack(spacing: 12) {
                        IconBadge(symbol: "heart.text.square.fill", color: Theme.red, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily check-in").font(.headline).foregroundStyle(Theme.text)
                            Text("Sleep, soreness and energy. 10 seconds.").font(.caption).foregroundStyle(Theme.text2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.text3)
                    }
                    .cardStyle(padding: 14)
                }
                .buttonStyle(PressableStyle())
            }
        }
        .sheet(isPresented: $checkingIn) { CheckInSheet().environmentObject(store) }
    }
}

struct CheckInSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var sleep = 8.0
    @State private var soreness = 2
    @State private var energy = 4

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Overline("Sleep last night")
                        HStack {
                            Text(String(format: "%.1f hours", sleep)).font(.number(28)).foregroundStyle(Theme.text)
                            Spacer()
                            TargetStepper(value: "", minus: { sleep = max(3, sleep - 0.5) }, plus: { sleep = min(13, sleep + 0.5) })
                        }
                    }
                    .cardStyle()
                    scale("Soreness", ["None", "Light", "Some", "Sore", "Very"], $soreness, Theme.red)
                    scale("Energy", ["Dead", "Low", "Okay", "Good", "Great"], $energy, Theme.green)
                    Button {
                        store.updateDaily { d in
                            d.sleep = sleep
                            d.soreness = soreness
                            d.energy = energy
                        }
                        store.notify(.success)
                        dismiss()
                    } label: { Label("Save check-in", systemImage: "checkmark") }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.green))
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear {
                let log = store.daily()
                if let s = log.sleep { sleep = s }
                if let s = log.soreness { soreness = s }
                if let e = log.energy { energy = e }
            }
        }
        .presentationDetents([.large])
    }

    private func scale(_ title: String, _ labels: [String], _ value: Binding<Int>, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline(title)
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { v in
                    Button { value.wrappedValue = v; store.haptic(.light) } label: {
                        VStack(spacing: 4) {
                            Text("\(v)").font(.number(18))
                            Text(labels[v - 1]).font(.system(size: 10, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(value.wrappedValue == v ? Theme.bg : Theme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(value.wrappedValue == v ? color : Theme.surface2))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .cardStyle()
    }
}
