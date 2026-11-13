import SwiftUI
import UserNotifications

/// First-run setup. Pages depend on what you train for, and everything here can be changed later in Profile.
struct OnboardingView: View {
    @EnvironmentObject var store: Store

    enum Goal: String, CaseIterable, Identifiable {
        case hockey, track, both, fitness
        var id: String { rawValue }
        var title: String {
            switch self {
            case .hockey: "Hockey"
            case .track: "Track & Field"
            case .both: "Hockey and track"
            case .fitness: "General fitness"
            }
        }
        var detail: String {
            switch self {
            case .hockey: "Off-ice strength, speed and power, plus shooting and stickhandling."
            case .track: "Sprints, hurdles, jumps, throws or distance, built around your events."
            case .both: "Two separate setups. Switch any time from the top of Today."
            case .fitness: "Full body, upper, legs, abs, HIIT, runs and mobility."
            }
        }
        var symbol: String {
            switch self {
            case .hockey: "figure.hockey"
            case .track: "figure.track.and.field"
            case .both: "arrow.triangle.2.circlepath"
            case .fitness: "figure.strengthtraining.functional"
            }
        }
    }

    enum Page: Hashable { case welcome, you, hockey, track, training, schedule, reminders, gear, body, features, done }

    @State private var goal = Goal.hockey
    @State private var page: Page = {
        // Screenshot hook: -onboardPage track
        switch UserDefaults.standard.string(forKey: "onboardPage") {
        case "you": return .you
        case "track": return .track
        case "schedule": return .schedule
        default: return .welcome
        }
    }()
    @State private var trackEvents: [String] = UserDefaults.standard.string(forKey: "onboardPage") == "track" ? ["100", "200", "lj"] : []
    @State private var trainDays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var trainMinute = 17 * 60
    @State private var calendarLink = ""

    private var pages: [Page] {
        var p: [Page] = [.welcome, .you]
        if goal == .hockey || goal == .both { p.append(.hockey) }
        if goal == .track || goal == .both { p.append(.track) }
        p += [.training, .schedule, .reminders, .gear, .body, .features, .done]
        return p
    }
    private var index: Int { pages.firstIndex(of: page) ?? 0 }
    private var accent: Color { goal == .track ? Color(hex: 0xFF6B5E) : Theme.ice }
    private var s: Binding<Settings> { $store.data.settings }
    private var st: Settings { store.data.settings }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) { content }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .id(page)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
            .scrollDismissesKeyboard(.immediately)
            Button {
                hideKeyboard()
                next()
            } label: {
                Text(page == .done ? "Start training" : (page == .welcome ? "Get started" : "Continue"))
            }
            .buttonStyle(PrimaryButtonStyle(color: accent))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .screenBackground()
        .animation(.easeInOut(duration: 0.25), value: page)
    }

    // MARK: Chrome

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                if index > 0 {
                    Button { hideKeyboard(); page = pages[index - 1] } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.text2)
                            .frame(width: 36, height: 36)
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
                Spacer()
                Text(index == 0 ? "" : "\(index) of \(pages.count - 1)").font(.number(12, .semibold)).foregroundStyle(Theme.text3)
                Spacer()
                if page != .done && page != .welcome && page != .you {
                    Button("Skip") { hideKeyboard(); next() }.font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text2)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surface2)
                    Capsule().fill(accent).frame(width: geo.size.width * CGFloat(index) / CGFloat(max(1, pages.count - 1)))
                }
            }
            .frame(height: 4)
            .opacity(index == 0 ? 0 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private func title(_ over: String, _ text: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Overline(over, color: accent)
            Text(text).font(.display(34)).foregroundStyle(Theme.text).fixedSize(horizontal: false, vertical: true)
            Text(sub).font(.subheadline).foregroundStyle(Theme.text2).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    private func section(_ label: String) -> some View {
        Text(label.uppercased()).font(.caption.weight(.bold)).tracking(1).foregroundStyle(Theme.text3).padding(.top, 6)
    }

    private func choice<T: Hashable>(_ value: T, _ selection: Binding<T>, _ title: String, _ detail: String? = nil, symbol: String? = nil) -> some View {
        let on = selection.wrappedValue == value
        return Button { selection.wrappedValue = value; store.haptic(.light) } label: {
            HStack(spacing: 12) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).foregroundStyle(on ? Theme.bg : accent)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(on ? accent : accent.opacity(0.14)))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(Theme.text)
                    if let detail { Text(detail).font(.footnote).foregroundStyle(Theme.text2).multilineTextAlignment(.leading) }
                }
                Spacer(minLength: 0)
                Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(on ? accent : Theme.text3)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(on ? accent.opacity(0.7) : Theme.stroke, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(PressableStyle())
    }

    private func chips<T: Hashable>(_ options: [(T, String)], _ selection: Binding<T>) -> some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.0) { v, label in
                let on = selection.wrappedValue == v
                Button { selection.wrappedValue = v; store.haptic(.light) } label: {
                    Text(label).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundStyle(on ? Theme.bg : Theme.text)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(on ? accent : Theme.surface))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private func toggleRow(_ title: String, _ detail: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.text)
                Text(detail).font(.footnote).foregroundStyle(Theme.text2)
            }
        }
        .tint(accent)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(get: { Day.start(Date()).addingTimeInterval(TimeInterval(minutes.wrappedValue * 60)) },
                set: { d in
                    let c = Day.cal.dateComponents([.hour, .minute], from: d)
                    minutes.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0)
                })
    }

    // MARK: Pages

    @ViewBuilder
    private var content: some View {
        switch page {
        case .welcome: welcome
        case .you: you
        case .hockey: hockey
        case .track: track
        case .training: training
        case .schedule: schedule
        case .reminders: reminders
        case .gear: gear
        case .body: bodyPage
        case .features: features
        case .done: done
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.ice.opacity(0.35), Color(hex: 0xFF6B5E).opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "bolt.heart.fill").font(.system(size: 64, weight: .bold)).foregroundStyle(Theme.text)
            }
            .frame(height: 170)
            title("Edgework", "Train for your sport, every day.",
                  "A fresh workout every day that fits your schedule, your gear and how hard you want to push.")
            feature("wand.and.stars", "Daily workout generator", "Rotates strength, speed, power, conditioning and mobility. Adjusts around games and meets.")
            feature("rotate.3d", "\(Library.all.count) exercises in 3D", "Drag the demo figure around, slow it down, and read the steps and cues.")
            feature("plusminus", "Scale anything", "One slider for overall intensity, plus −/+ on any single exercise.")
            feature("fork.knife", "Fuel and progress", "Food log with barcode scanning, diet notes, streaks, PRs and GPS runs.")
        }
    }

    private var you: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("About you", "What are you training for?", "This sets up your workouts, tools and theme.")
            TextField("Your first name", text: s.name)
                .textContentType(.givenName)
                .submitLabel(.done)
                .onSubmit { hideKeyboard() }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
            ForEach(Goal.allCases) { g in choice(g, $goal, g.title, g.detail, symbol: g.symbol) }
        }
    }

    private var hockey: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Hockey", "Your game", "Forwards get more speed work, defense more strength, goalies get their own drills.")
            section("Position")
            chips(Position.allCases.map { ($0, $0.title) }, s.position)
            section("Workout mix")
            ForEach(TrainingStyle.allCases) { t in choice(t, s.style, t.title, t.detail) }
            section("Pucks you own")
            HStack {
                Text("\(st.puckCount) pucks").font(.headline).foregroundStyle(Theme.text)
                Spacer()
                TargetStepper(value: "\(st.puckCount)", minus: { store.data.settings.puckCount = max(1, st.puckCount - 1) },
                              plus: { store.data.settings.puckCount = min(200, st.puckCount + 1) })
            }
            .cardStyle(padding: 14)
            section("Daily shot goal")
            chips([(0, "Off"), (50, "50"), (100, "100"), (200, "200"), (300, "300")], s.shotGoal)
        }
    }

    private var track: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Track & Field", "Your events", "Your daily workouts are built around these. Pick as many as you like.")
            let groups: [(String, [String])] = [("Sprints", ["60", "100", "200", "400"]), ("Hurdles", ["100h", "110h", "300h", "400h"]),
                                                ("Distance", ["800", "1600", "3200"]), ("Jumps", ["lj", "tj", "hj", "pv"]), ("Throws", ["sp", "dt", "jt"])]
            ForEach(groups, id: \.0) { name, ids in
                section(name)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(ids, id: \.self) { id in
                        let on = trackEvents.contains(id)
                        Button {
                            if on { trackEvents.removeAll { $0 == id } } else { trackEvents.append(id) }
                            store.haptic(.light)
                        } label: {
                            HStack {
                                Text(TrackEventDef.byID[id]?.name ?? id).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                                Image(systemName: on ? "checkmark.circle.fill" : "plus.circle").foregroundStyle(on ? Theme.bg : Color(hex: 0xFF6B5E))
                            }
                            .foregroundStyle(on ? Theme.bg : Theme.text)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(on ? Color(hex: 0xFF6B5E) : Theme.surface))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
            if !trackEvents.isEmpty {
                Text("Workouts will rotate: \(Store.trackRotation(for: trackEvents).prefix(5).map(\.title).joined(separator: ", ")) and more.")
                    .font(.footnote).foregroundStyle(Theme.text2).padding(.top, 4)
            }
        }
    }

    private var training: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Training", "How much, how hard?", "You can always rebuild a workout, swap moves or change the length on the day.")
            section("Season")
            chips(SeasonPhase.allCases.map { ($0, $0.title) }, s.phase)
            Text(st.phase.detail).font(.footnote).foregroundStyle(Theme.text3)
            section("Usual workout length")
            chips([(15, "15"), (20, "20"), (30, "30"), (45, "45"), (60, "60")].map { ($0.0, $0.1 + " min") }, s.duration)
            section("Experience")
            choice(1, s.maxLevel, "New to training", "Beginner moves only, lighter volume.")
            choice(2, s.maxLevel, "Some experience", "Up to intermediate moves.")
            choice(3, s.maxLevel, "Experienced", "Everything, including advanced plyometrics.")
            section("Rest between sets")
            chips(RestLength.allCases.map { ($0, $0.title) }, s.rest)
            toggleRow("Low impact", "No jumping or explosive moves (sore joints, small apartment).", s.lowImpact)
        }
        .onChange(of: st.maxLevel) { _, lvl in
            store.data.settings.intensity = lvl == 1 ? 0.8 : (lvl == 2 ? 0.95 : 1.0)
        }
    }

    private var schedule: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Schedule", "When do you train?", "No fixed plan needed. These days get a workout reminder; the others are rest days.")
            WeekdayPicker(title: "Training days", color: accent, selection: $trainDays)
                .cardStyle(padding: 14)
            HStack {
                Text("Usual time").font(.headline).foregroundStyle(Theme.text)
                Spacer()
                DatePicker("", selection: timeBinding($trainMinute), displayedComponents: .hourAndMinute).labelsHidden()
            }
            .cardStyle(padding: 14)
            section(goal == .track ? "Meet & practice calendar" : "Team calendar")
            VStack(alignment: .leading, spacing: 8) {
                TextField("Paste a webcal:// or https:// calendar link", text: $calendarLink)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).font(.footnote)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface2))
                Text("Optional. From TeamSnap, Crossbar, SportsEngine, Google Calendar or any app that shares a calendar link. You can also open an .ics file with Edgework later.")
                    .font(.caption).foregroundStyle(Theme.text3)
            }
            .cardStyle(padding: 14)
            toggleRow(goal == .track ? "Keep normal workouts on meet days" : "Keep normal workouts on game days",
                      "Train after the event instead of a short activation. Workouts after events are lighter.", s.normalOnEventDays)
        }
    }

    private var reminders: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Reminders", "Nudges that help", "All optional. You'll get asked for notification permission once.")
            toggleRow("Workout reminder", "At your training time on training days.", s.remindDaily)
            toggleRow("Streak saver", "If you haven't trained by the evening.", s.remindStreak)
            if st.remindStreak {
                HStack {
                    Text("Streak saver time")
                    Spacer()
                    DatePicker("", selection: timeBinding(s.streakMinute), displayedComponents: .hourAndMinute).labelsHidden()
                }
                .cardStyle(padding: 14)
            }
            toggleRow("Water", "Every couple of hours during the day.", s.remindWater)
            toggleRow(goal == .track ? "Meet day" : "Game day", goal == .track ? "Carb meal and warm-up reminders before meets." : "Activation reminder before games.", s.remindGame)
            if goal != .track {
                toggleRow("Shot goal", "An evening nudge if you're short of today's shots.", s.remindShots)
            }
        }
    }

    private var gear: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Equipment", "What do you have?", "Bodyweight moves are always in. Pick everything you can use.")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Equipment.allCases) { e in
                    let on = st.equipment.contains(e)
                    Button {
                        if on { store.data.settings.equipment.remove(e) } else { store.data.settings.equipment.insert(e) }
                        store.haptic(.light)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: e.symbol).frame(width: 20)
                            Text(e.title).font(.system(size: 14, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(on ? Theme.bg : Theme.text)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(on ? accent : Theme.surface))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private var bodyPage: some View {
        let imperial = st.units == .imperial
        return VStack(alignment: .leading, spacing: 12) {
            title("Fuel", "Food targets", "Used for calorie and protein targets in the food log. Skip if you don't want to track food.")
            toggleRow("Food log", "Fuel tab with meals, barcode scanning and diet notes.", s.showFuel)
            if st.showFuel {
                section("Units")
                chips(Units.allCases.map { ($0, $0.title) }, s.units)
                section("Goal")
                chips(NutritionGoal.allCases.map { ($0, $0.title) }, s.nutritionGoal)
                section("About you")
                VStack(spacing: 10) {
                    chips(Sex.allCases.map { ($0, $0.title) }, s.sex)
                    Stepper("Age: \(st.age)", value: s.age, in: 10...80)
                    Stepper(imperial ? "Weight: \(Int((st.weightKg * 2.20462).rounded())) lb" : "Weight: \(Int(st.weightKg.rounded())) kg",
                            value: Binding(get: { imperial ? st.weightKg * 2.20462 : st.weightKg },
                                           set: { store.data.settings.weightKg = imperial ? $0 / 2.20462 : $0 }), in: 50...400, step: 1)
                    Stepper(imperial ? "Height: \(Int(st.heightCm / 2.54) / 12)' \(Int(st.heightCm / 2.54) % 12)\"" : "Height: \(Int(st.heightCm)) cm",
                            value: Binding(get: { imperial ? st.heightCm / 2.54 : st.heightCm },
                                           set: { store.data.settings.heightCm = imperial ? $0 * 2.54 : $0 }), in: 40...230, step: 1)
                }
                .cardStyle(padding: 14)
                Text("About \(Int(store.targets.kcal)) kcal and \(Int(store.targets.protein)) g protein a day.")
                    .font(.footnote).foregroundStyle(Theme.text2)
            }
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Make it yours", "Turn on what you'll use", "Everything here is in Profile › Features later.")
            toggleRow("3D exercise figures", "Drag to rotate, with a speed slider. Off shows simple icons.", s.figures3D)
            toggleRow("Daily readiness check-in", "Sleep, soreness and energy. Lightens hard days.", s.showReadiness)
            toggleRow("Daily goals card", "Water, running and sport goals on Today.", s.showDailyGoals)
            toggleRow("Coach's notes", "Short tips that cycle on Today.", s.showTips)
            if st.showFuel { toggleRow("Meal generator", "Meal ideas sized to what's left today.", s.showMealGenerator) }
            toggleRow("Lock Screen & Dynamic Island", "Live timers during workouts and GPS runs.", s.liveActivities)
            toggleRow("Review workouts before starting", "See the full list and swap or reorder first.", s.reviewFirst)
        }
    }

    private var done: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("All set", st.name.isEmpty ? "Let's get to work." : "Let's go, \(st.name).", "Here's how your training is set up. Change any of it in Profile.")
            VStack(alignment: .leading, spacing: 10) {
                summaryRow("figure.mixed.cardio", goal.title)
                if goal == .track || goal == .both, !trackEvents.isEmpty {
                    summaryRow("flag.checkered", trackEvents.compactMap { TrackEventDef.byID[$0]?.name }.joined(separator: ", "))
                }
                summaryRow("calendar", "\(trainDays.count) training days at \(Day.start(Date()).addingTimeInterval(TimeInterval(trainMinute * 60)).formatted(date: .omitted, time: .shortened))")
                summaryRow("timer", "\(st.duration)-minute workouts, \(st.phase.title.lowercased())")
                summaryRow("dumbbell.fill", st.equipment.isEmpty ? "Bodyweight only" : "\(st.equipment.count) pieces of equipment")
            }
            .cardStyle()
        }
    }

    private func summaryRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(accent).frame(width: 22)
            Text(text).font(.subheadline).foregroundStyle(Theme.text)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            IconBadge(symbol: symbol, color: accent, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.text)
                Text(text).font(.subheadline).foregroundStyle(Theme.text2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Flow

    private func next() {
        if page == .you {
            Theme.sport = goal == .track ? .track : .hockey
        }
        if page == .done { finish(); return }
        if index + 1 < pages.count { page = pages[index + 1] }
    }

    private func finish() {
        var st = store.data.settings
        st.trainTimes = Dictionary(uniqueKeysWithValues: trainDays.map { (String($0), trainMinute) })
        st.restDays = Set(1...7).subtracting(trainDays)
        st.remindMinute = trainMinute
        st.calendarURL = calendarLink.trimmingCharacters(in: .whitespacesAndNewlines)
        if goal == .fitness {
            st.style = .general
            st.includeHockey = false
            st.showHockeyTools = false
        }
        if goal == .track { st.sport = .track; st.keywords = Keywords.defaults(for: .track) }
        if !trackEvents.isEmpty {
            st.trackEvents = trackEvents
            st.trackGroup = Store.trackGroup(for: trackEvents)
        }
        store.data.settings = st
        if goal == .both {
            // Hockey is active now; set up track's own profile with the same personal settings and the chosen events.
            var t = Store.freshSettings(for: .track, onboarded: st)
            t.copyShared(from: st)
            t.trackEvents = trackEvents
            t.trackGroup = Store.trackGroup(for: trackEvents)
            t.trainTimes = st.trainTimes
            t.restDays = st.restDays
            t.remindDaily = st.remindDaily
            t.remindGame = st.remindGame
            store.data.profiles[Sport.track.rawValue] = SportProfile(settings: t)
        }
        Theme.sport = st.sport
        Appearance.apply()
        store.data.today = nil
        store.ensureToday()
        store.data.onboarded = true
        let wantsNotifications = st.remindDaily || st.remindStreak || st.remindWater || st.remindGame
        if wantsNotifications {
            Task {
                _ = await Notifier.requestPermission()
                Notifier.reschedule(store)
            }
        }
        if !st.calendarURL.isEmpty { Task { _ = await store.syncCalendar() } }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
