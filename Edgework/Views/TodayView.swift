import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: Store
    @State private var previewDay: Date?
    @State private var logging = false
    @State private var showProfile = false

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        let base = h < 12 ? "Morning" : (h < 18 ? "Afternoon" : "Evening")
        let name = store.data.settings.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Good \(base.lowercased())" : "\(base), \(name)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    WeekStrip(onSelect: { previewDay = $0 })
                    if let next = store.upcomingEvents.first(where: { $0.start < Day.add(8, to: Date()) }) {
                        NextEventCard(event: next)
                    }
                    if let today = store.data.today {
                        TodayHero(state: today)
                    }
                    if store.data.settings.showReadiness { ReadinessCard() }
                    if store.data.settings.showDailyGoals { DailyGoalsCard() }
                    IntensityCard()
                    statsRow
                    Button { logging = true } label: {
                        Label("Log an activity", systemImage: "square.and.pencil")
                    }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.ice))
                    quickStarts
                    if store.data.settings.showTips { tipCard }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .screenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showProfile) {
                SettingsView().environmentObject(store)
            }
            .sheet(isPresented: $logging) {
                ManualLogView().environmentObject(store)
            }
            .sheet(item: Binding(get: { previewDay.map { IdentifiedDate(date: $0) } }, set: { previewDay = $0?.date })) { d in
                DayPreviewSheet(date: d.date)
                    .environmentObject(store)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                SportMenu().padding(.bottom, 6)
                Overline(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                Text(greeting)
                    .font(.display(34))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            Button { showProfile = true } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Theme.ice)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.top, 12)
    }

    private var statsRow: some View {
        let week = store.weekSessions
        return HStack(spacing: 10) {
            StatTile(value: "\(store.currentStreak)", label: "Day streak", symbol: "flame.fill", color: Theme.amber)
            StatTile(value: "\(week.count)", label: "This week", symbol: "calendar", color: Theme.ice)
            StatTile(value: "\(week.reduce(0) { $0 + $1.minutes })", label: "Minutes", symbol: "stopwatch.fill", color: Theme.green)
        }
    }

    private var quickStarts: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Quick start", subtitle: "Ready-made sessions")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Programs.forSport(store.data.settings.sport).prefix(8)) { p in
                        NavigationLink {
                            ProgramScreen(program: p)
                        } label: {
                            ProgramTile(program: p)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }

    private var tipCard: some View {
        let tip = Tips.forToday
        return HStack(alignment: .top, spacing: 12) {
            IconBadge(symbol: "lightbulb.fill", color: Theme.amber, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Overline("Coach's note", color: Theme.amber)
                Text(tip).font(.subheadline).foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle()
    }
}

struct IdentifiedDate: Identifiable {
    let date: Date
    var id: String { Day.key(date) }
}

// MARK: - Week strip

struct WeekStrip: View {
    @EnvironmentObject var store: Store
    let onSelect: (Date) -> Void

    var body: some View {
        let days = Day.week(of: Date())
        let active = store.activeDays
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { d in
                let isToday = Day.key(d) == Day.key(Date())
                let type = store.dayType(for: d)
                let done = active.contains(Day.key(d))
                Button { onSelect(d) } label: {
                    VStack(spacing: 6) {
                        Text(d.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isToday ? Theme.ice : Theme.text3)
                        Text(d.formatted(.dateTime.day()))
                            .font(.number(16))
                            .foregroundStyle(isToday ? Theme.bg : Theme.text)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(isToday ? Theme.ice : Color.clear))
                            .overlay(Circle().strokeBorder(done && !isToday ? Theme.green : Color.clear, lineWidth: 2))
                        Image(systemName: type == .off ? store.autoFocus(for: d).symbol : type.symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(type == .off ? Theme.text3 : type.color)
                            .frame(height: 14)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(.horizontal, 4)
        .cardStyle(padding: 4)
    }
}

// MARK: - Next event

struct NextEventCard: View {
    @EnvironmentObject var store: Store
    let event: CalEvent

    var body: some View {
        let game = store.kind(event) == .game
        let color = game ? Theme.red : Theme.ice
        HStack(spacing: 12) {
            IconBadge(symbol: game ? "flag.checkered" : "figure.ice.skating", color: color, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Overline(Day.key(event.start) == Day.key(Date()) ? (game ? "Game today" : "Practice today") : (game ? "Next game" : "Next practice"), color: color)
                Text(event.title).font(.headline).foregroundStyle(Theme.text).lineLimit(1)
                Text(event.allDay ? event.start.formatted(.dateTime.weekday(.wide).month().day())
                                  : event.start.formatted(.dateTime.weekday(.wide).hour().minute()))
                    .font(.footnote).foregroundStyle(Theme.text2)
            }
            Spacer()
        }
        .cardStyle(padding: 14)
    }
}

// MARK: - Hero

struct TodayHero: View {
    @EnvironmentObject var store: Store
    let state: TodayState
    @State private var reviewing = false

    private let durations = [10, 15, 20, 30, 45, 60, 75, 90]

    var body: some View {
        let w = state.workout
        let dayType = store.dayType(for: Date())
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Chip(text: store.dayTitle(dayType), symbol: dayType.symbol, color: dayType.color)
                if let m = store.data.settings.trainTimes[String(Day.cal.component(.weekday, from: Date()))] {
                    Chip(text: Day.start(Date()).addingTimeInterval(TimeInterval(m * 60)).formatted(date: .omitted, time: .shortened),
                         symbol: "clock", color: Theme.text2)
                }
                Spacer()
                Menu {
                    Picker("Focus", selection: Binding(get: { state.focus }, set: { store.setTodayFocus($0) })) {
                        Label("Auto (\(store.autoFocus(for: Date()).shortTitle))", systemImage: "sparkles").tag(Focus?.none)
                        ForEach(Focus.generatable(for: store.data.settings.sport)) { f in
                            Label(f.title, systemImage: f.symbol).tag(Focus?.some(f))
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.text)
                        .frame(width: 34, height: 34).background(Circle().fill(Color.white.opacity(0.1)))
                }
                Button { withAnimation(.snappy) { store.reroll() } } label: {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.text)
                        .frame(width: 34, height: 34).background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(PressableStyle())
            }

            VStack(alignment: .leading, spacing: 6) {
                if let after = store.afterEventLabel(for: Date()) {
                    Chip(text: after, symbol: "arrow.turn.down.right", color: Theme.amber)
                }
                Overline("Today's workout", color: w.focus.color)
                Text(w.title).font(.display(32)).foregroundStyle(Theme.text)
                Text(w.subtitle).font(.subheadline).foregroundStyle(Theme.text2)
            }

            HStack(spacing: 14) {
                metric("\(store.estimateMinutes(w))", "min")
                metric("\(w.items.count)", "moves")
                metric("\(w.totalSets)", "sets")
                Spacer()
                Menu {
                    ForEach(durations, id: \.self) { m in
                        Button { store.setTodayDuration(m) } label: {
                            if m == state.duration { Label("\(m) min", systemImage: "checkmark") } else { Text("\(m) min") }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(state.duration)m")
                        Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .fixedSize()
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                }
            }

            CompositionBar(categories: w.mainCategories)

            HStack(spacing: 10) {
                Button {
                    if store.data.settings.reviewFirst { reviewing = true } else { store.start(w) }
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: w.focus.color))
                NavigationLink {
                    TodayWorkoutScreen()
                } label: {
                    Text("Details")
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: 110)
            }
        }
        .padding(18)
        .background(
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.surface)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [w.focus.color.opacity(0.28), w.focus.color.opacity(0.0)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: w.focus.symbol)
                    .font(.system(size: 150, weight: .bold))
                    .foregroundStyle(w.focus.color.opacity(0.07))
                    .rotationEffect(.degrees(-8))
                    .offset(x: 24, y: -40)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(w.focus.color.opacity(0.25)))
        .navigationDestination(isPresented: $reviewing) { TodayWorkoutScreen() }
    }

    private func metric(_ v: String, _ label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(v).font(.number(22)).foregroundStyle(Theme.text)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
        }
        .fixedSize()
    }
}

// MARK: - Intensity

struct IntensityCard: View {
    @EnvironmentObject var store: Store

    static func label(_ v: Double) -> String {
        switch v {
        case ..<0.75: "Recovery pace"
        case ..<0.95: "Dialed back"
        case ..<1.06: "Standard"
        case ..<1.3: "Pushing it"
        default: "Max effort"
        }
    }

    var body: some View {
        let pct = Int((store.intensity * 100).rounded())
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Overline("Global intensity")
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(pct)%").font(.number(34)).foregroundStyle(Theme.text)
                            .contentTransition(.numericText())
                        Text(Self.label(store.intensity)).font(.subheadline.weight(.semibold))
                            .foregroundStyle(pct == 100 ? Theme.text2 : (pct < 100 ? Theme.ice : Theme.amber))
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                    RoundIconButton(symbol: "minus", size: 42) { withAnimation { store.adjustAll(up: false) } }
                    RoundIconButton(symbol: "plus", size: 42) { withAnimation { store.adjustAll(up: true) } }
                }
            }
            Slider(value: $store.data.settings.intensity, in: 0.4...2.0, step: 0.05)
                .tint(pct <= 100 ? Theme.ice : Theme.amber)
            Text("Scales every rep, timer and distance in every workout. Use − / + on any single exercise to tune just that one.")
                .font(.caption).foregroundStyle(Theme.text3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }
}

// MARK: - Program tile

struct ProgramTile: View {
    @EnvironmentObject var store: Store
    let program: Program

    var body: some View {
        let w = program.workout(rest: store.data.settings.rest)
        VStack(alignment: .leading, spacing: 10) {
            IconBadge(symbol: program.focus.symbol, color: program.focus.color, size: 38)
            Spacer(minLength: 0)
            Text(program.title).font(.display(19, .bold)).foregroundStyle(Theme.text)
                .lineLimit(2).multilineTextAlignment(.leading)
            Text("\(store.estimateMinutes(w)) min · \(w.items.count) moves")
                .font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
        }
        .padding(14)
        .frame(width: 160, height: 160, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [program.focus.color.opacity(0.22), Theme.surface], startPoint: .topLeading, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.stroke))
    }
}

// MARK: - Day preview

struct DayPreviewSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let date: Date

    var body: some View {
        let isToday = Day.key(date) == Day.key(Date())
        let workout = isToday ? (store.data.today?.workout ?? store.preview(for: date)) : store.preview(for: date)
        let done = store.sessions(on: date)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Overline("Day type")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DayType.allCases) { t in
                                    let selected = store.dayType(for: date) == t
                                    Button {
                                        store.setDayType(t == store.scheduledType(for: date) ? nil : t, for: date)
                                    } label: {
                                        Chip(text: store.dayTitle(t), symbol: t.symbol, color: t == .off ? Theme.ice : t.color, filled: selected)
                                    }
                                    .buttonStyle(PressableStyle())
                                }
                            }
                        }
                        Text("Change this when your schedule shifts. Game days get a short activation, the day after gets a recovery flush.")
                            .font(.caption).foregroundStyle(Theme.text3)
                    }
                    .cardStyle()

                    if !done.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Overline("Completed", color: Theme.green)
                            ForEach(done) { s in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green)
                                    Text(s.title).foregroundStyle(Theme.text)
                                    Spacer()
                                    Text("\(s.minutes) min").foregroundStyle(Theme.text2).font(.number(14))
                                }
                            }
                        }
                        .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Overline(isToday ? "Today's plan" : "Planned", color: workout.focus.color)
                        Text(workout.title).font(.display(28)).foregroundStyle(Theme.text)
                        Text("\(store.estimateMinutes(workout)) min · \(workout.items.count) moves · \(workout.totalSets) sets")
                            .font(.subheadline).foregroundStyle(Theme.text2)
                    }
                    VStack(spacing: 0) {
                        ForEach(workout.ordered) { item in
                            if let ex = item.exercise {
                                ExerciseRowLabel(exercise: ex, trailing: "\(item.sets)×\(store.targetText(item))")
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .cardStyle(padding: 12)

                    Button {
                        dismiss()
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            store.start(workout)
                        }
                    } label: {
                        Label(isToday ? "Start" : "Do this one now", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: workout.focus.color))
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle(date.formatted(.dateTime.weekday(.wide).month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.bg)
    }
}

enum Tips {
    static let all = [
        "Skating is a single-leg sport. If you only have time for one strength move, make it a split squat.",
        "Groin strains are the most common hockey muscle injury. Copenhagen planks twice a week cut the risk dramatically.",
        "On game day, keep it short and sharp. You want to feel fast, not tired.",
        "Sleep is the best recovery tool you have. Aim for 8+ hours, especially after games.",
        "Hydrate before you're thirsty. Even 2% dehydration slows your reaction time.",
        "Hockey shifts are 30–50 seconds of max effort. Train intervals in that range, not long slow runs.",
        "Quality over quantity on jumps. Stop the set when they stop being explosive.",
        "Tight hip flexors steal stride length. Couch stretch after every skate.",
        "Eyes up when you stickhandle. If you can see the puck, you can't see the play.",
        "Strength is the base. Speed and power are built on top of it, so don't skip the boring lifts.",
        "Too hard? Tap − on the exercise. The app remembers it for next time.",
        "Feeling great? Bump global intensity to 105% and see if it sticks for a week.",
        "Eat protein within a couple of hours after training: around 20–40 g.",
        "A 2-minute walk between periods beats sitting still for recovery.",
    ]

    static var forToday: String { all[Day.seed(Date()) % all.count] }
}
