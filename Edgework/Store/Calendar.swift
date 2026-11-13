import Foundation
import UserNotifications

/// Minimal iCalendar (.ics) reader: VEVENT start, title, location and UID.
enum ICS {
    static func parse(_ text: String) -> [CalEvent] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var lines: [String] = []
        for raw in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            if (raw.hasPrefix(" ") || raw.hasPrefix("\t")), !lines.isEmpty {
                lines[lines.count - 1] += String(raw.dropFirst())
            } else {
                lines.append(String(raw))
            }
        }

        var events: [CalEvent] = []
        var current: [String: (params: String, value: String)]?
        for line in lines {
            if line == "BEGIN:VEVENT" {
                current = [:]
            } else if line == "END:VEVENT" {
                if let c = current, let e = event(from: c) { events.append(e) }
                current = nil
            } else if current != nil, let colon = line.firstIndex(of: ":") {
                let key = String(line[..<colon])
                let value = String(line[line.index(after: colon)...])
                let name = key.split(separator: ";").first.map(String.init)?.uppercased() ?? key
                current?[name] = (key, value)
            }
        }
        return events
    }

    private static func event(from c: [String: (params: String, value: String)]) -> CalEvent? {
        guard let start = c["DTSTART"], let date = parseDate(start.value, params: start.params) else { return nil }
        if c["STATUS"]?.value.uppercased() == "CANCELLED" { return nil }
        let title = unescape(c["SUMMARY"]?.value ?? "Event")
        let allDay = start.params.uppercased().contains("VALUE=DATE") || start.value.count == 8
        let uid = c["UID"]?.value ?? "\(title)-\(start.value)"
        let end = c["DTEND"].flatMap { parseDate($0.value, params: $0.params) }
        return CalEvent(id: uid + "|" + start.value, title: title, start: date, allDay: allDay,
                        location: unescape(c["LOCATION"]?.value ?? ""), guessed: .ignore, end: end)
    }

    private static func unescape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\n", with: " ").replacingOccurrences(of: "\\N", with: " ")
            .replacingOccurrences(of: "\\,", with: ",").replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    private static func parseDate(_ value: String, params: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        let v = value.trimmingCharacters(in: .whitespaces)
        if v.count == 8 {
            f.timeZone = .current
            f.dateFormat = "yyyyMMdd"
            return f.date(from: v)
        }
        if v.hasSuffix("Z") {
            f.timeZone = TimeZone(identifier: "UTC")
            f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            return f.date(from: v)
        }
        if let range = params.range(of: "TZID=") {
            let tz = params[range.upperBound...].split(separator: ";").first.map(String.init) ?? ""
            f.timeZone = TimeZone(identifier: tz.replacingOccurrences(of: "\"", with: "")) ?? .current
        } else {
            f.timeZone = .current
        }
        f.dateFormat = "yyyyMMdd'T'HHmmss"
        return f.date(from: String(v.prefix(15)))
    }
}

extension Store {
    // MARK: Calendar

    /// Replaces stored events with a parsed calendar. Returns how many games/practices were recognised.
    @discardableResult
    func applyCalendar(_ text: String) -> (total: Int, recognised: Int) {
        let cutoff = Day.add(-30, to: Date())
        let events = ICS.parse(text).filter { $0.start >= cutoff }
        data.events = events.sorted { $0.start < $1.start }
        data.lastSync = Date()
        if data.today?.focus == nil {
            rebuildToday(seed: data.today?.seed ?? Day.seed(Date()), focus: nil, duration: defaultDuration(for: Date()))
        }
        Notifier.reschedule(self)
        return (events.count, events.filter { kind($0).counts }.count)
    }

    func syncCalendar() async -> String {
        var link = data.settings.calendarURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !link.isEmpty else { return "Add a calendar link first." }
        if link.lowercased().hasPrefix("webcal://") { link = "https://" + String(link.dropFirst("webcal://".count)) }
        guard let url = URL(string: link) else { return "That link doesn't look right." }
        do {
            let (raw, _) = try await URLSession.shared.data(from: url)
            guard let text = String(data: raw, encoding: .utf8), text.contains("BEGIN:VCALENDAR") else {
                return "That link didn't return a calendar."
            }
            let r = applyCalendar(text)
            return "Synced \(r.total) events, \(r.recognised) games/practices."
        } catch {
            return "Couldn't reach the calendar: \(error.localizedDescription)"
        }
    }

    func importCalendar(from url: URL) -> String {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        guard let raw = try? Data(contentsOf: url), let text = String(data: raw, encoding: .utf8) ?? String(data: raw, encoding: .isoLatin1),
              text.contains("BEGIN:VCALENDAR") else {
            return "That file isn't a calendar (.ics)."
        }
        let r = applyCalendar(text)
        return "Imported \(r.total) events, \(r.recognised) games/practices."
    }

    func setKind(_ kind: EventKind, for event: CalEvent) {
        data.eventKinds[event.id] = kind == CalEvent.guess(event.title, allDay: event.allDay, settings: data.settings) ? nil : kind
        if data.today?.focus == nil {
            rebuildToday(seed: data.today?.seed ?? Day.seed(Date()), focus: nil, duration: defaultDuration(for: Date()))
        }
        Notifier.reschedule(self)
    }

    // MARK: Manual logging

    func logManual(activity: Activity, title: String, date: Date, minutes: Int, distanceKm: Double?, rpe: Int, note: String, entries: [SessionEntry]) {
        let focus: Focus
        switch activity {
        case .run: focus = .run
        case .gym: focus = .fullBody
        case .walk, .bike, .swim: focus = .conditioning
        default: focus = .custom
        }
        let record = SessionRecord(date: date, title: title.isEmpty ? activity.title : title, focus: focus, duration: minutes * 60,
                                   entries: entries, rpe: rpe, feeling: .right, note: note, activity: activity, distance: distanceKm)
        data.sessions.append(record)
        data.sessions.sort { $0.date > $1.date }
        if activity == .run, let km = distanceKm, km > 0 { updateDaily(date) { $0.runKm += km } }
        if !entries.isEmpty { creditDaily(from: record) }
        Notifier.reschedule(self)
    }
}

// MARK: - Notifications

enum Notifier {
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    @MainActor
    static func reschedule(_ store: Store) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let st = store.data.settings
        let cal = Day.cal
        let now = Date()
        var requests: [UNNotificationRequest] = []

        func add(_ id: String, _ title: String, _ body: String, at date: Date) {
            guard date > now else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            requests.append(UNNotificationRequest(identifier: id, content: content,
                                                  trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
        }

        if st.remindDaily {
            for d in 0..<7 {
                let day = Day.add(d, to: Day.start(now))
                if d == 0 && !store.sessions(on: day).isEmpty { continue }
                let wd = Day.cal.component(.weekday, from: day)
                let minute: Int
                if st.normalOnEventDays, let e = store.events(on: day).last, !e.allDay {
                    let end = e.end ?? e.start.addingTimeInterval(90 * 60)
                    let after = end.addingTimeInterval(45 * 60)
                    minute = Day.cal.component(.hour, from: after) * 60 + Day.cal.component(.minute, from: after)
                } else if st.trainTimes.isEmpty {
                    minute = st.remindMinute
                } else if let m = st.trainTimes[String(wd)] {
                    minute = m
                } else {
                    continue
                }
                let w = d == 0 ? (store.data.today?.workout ?? store.preview(for: day)) : store.preview(for: day)
                add("daily-\(d)", "Workout time: \(w.title)", "\(store.estimateMinutes(w)) min · \(w.items.count) exercises. Let's go.",
                    at: day.addingTimeInterval(TimeInterval(minute * 60)))
            }
        }
        if st.runRemind {
            for d in 0..<7 {
                let day = Day.add(d, to: Day.start(now))
                let wd = Day.cal.component(.weekday, from: day)
                guard st.runRemindDays.contains(wd) else { continue }
                let done = store.weekRunKm
                add("run-\(d)", "Run day", "Weekly goal \(store.distanceText(st.runGoalKm)), \(store.distanceText(done)) done so far. Lace up.",
                    at: day.addingTimeInterval(TimeInterval(st.runMinute * 60)))
            }
        }
        if st.remindWater {
            for d in 0..<2 {
                let day = Day.add(d, to: Day.start(now))
                for h in [10, 12, 14, 16, 18, 20] {
                    add("water-\(d)-\(h)", "Drink some water", "Goal: \(st.waterGoal) glasses today. Tap to log one.",
                        at: day.addingTimeInterval(TimeInterval(h * 3600)))
                }
            }
        }
        if st.shotGoal > 0 && st.remindDaily && st.sport == .hockey {
            let shots = store.daily().totalShots
            if shots < st.shotGoal, let at = cal.date(bySettingHour: 19, minute: 0, second: 0, of: now) {
                add("shots", "\(st.shotGoal - shots) shots to go", "Your daily goal is \(st.shotGoal). Grab the pucks.", at: at)
            }
        }
        if st.remindGame && st.sport == .hockey {
            for e in store.upcomingEvents.prefix(20) where store.kind(e) == .game && !e.allDay {
                add("game-\(e.id)", "Game day: \(e.title)", "Do your 15-minute activation about 2–3 hours before puck drop.",
                    at: e.start.addingTimeInterval(-3 * 3600))
            }
        }
        if st.sport == .track {
            for e in store.upcomingEvents.prefix(20) where store.kind(e) == .game && !e.allDay {
                if st.remindMeetWarmup {
                    add("meet-warm-\(e.id)", "Warm-up time: \(e.title)", "Jog, drills, strides. Stay warm between events.",
                        at: e.start.addingTimeInterval(TimeInterval(-st.meetWarmupMinutes * 60)))
                }
                if st.remindGame {
                    add("meet-\(e.id)", "Meet day: \(e.title)", "Eat a carb-heavy meal 3–4 h before, pack spikes, water and a snack.",
                        at: e.start.addingTimeInterval(-4 * 3600))
                }
            }
        }
        if st.remindStreak && store.currentStreak > 0 && store.sessions(on: now).isEmpty {
            if let at = cal.date(bySettingHour: 20, minute: 0, second: 0, of: now) {
                add("streak", "Keep your \(store.currentStreak)-day streak", "Even a 15-minute mobility session counts.", at: at)
            }
        }
        for r in requests.prefix(60) { center.add(r) }
    }
}
