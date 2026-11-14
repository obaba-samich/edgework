import Foundation

/// What the Home Screen widgets show. The app writes it to the shared App Group container; the widget reads it.
struct WidgetSnapshot: Codable, Equatable {
    var date: Date
    var workoutTitle: String
    var workoutMinutes: Int
    var exerciseCount: Int
    var doneToday: Bool
    var streak: Int
    var shotsToday: Int
    var shotGoal: Int
    var hockey: Bool
    var accent: UInt32
    var nextEvent: String?
    var nextEventDate: Date?

    static let placeholder = WidgetSnapshot(date: Date(), workoutTitle: "Power", workoutMinutes: 35, exerciseCount: 9, doneToday: false,
                                            streak: 6, shotsToday: 60, shotGoal: 100, hockey: true, accent: 0x7CD4FF,
                                            nextEvent: "Game vs Wolves", nextEventDate: Date().addingTimeInterval(2 * 86400))

    /// AltStore and SideStore rename App Groups and list the real IDs under `ALTAppGroups`, so check those first.
    static var groupID: String? {
        let renamed = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] ?? []
        return (renamed + ["group.com.pizza.edgework"]).first {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil
        }
    }

    static var fileURL: URL? {
        groupID.flatMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }?
            .appendingPathComponent("widget.json")
    }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL, let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: raw)
    }

    /// Writes only when something changed. Returns true if it wrote.
    @discardableResult
    func save() -> Bool {
        guard let url = Self.fileURL, let raw = try? JSONEncoder().encode(self) else { return false }
        if let old = try? Data(contentsOf: url), let prev = try? JSONDecoder().decode(WidgetSnapshot.self, from: old),
           prev.sameContent(as: self) { return false }
        return (try? raw.write(to: url, options: .atomic)) != nil
    }

    private func sameContent(as o: WidgetSnapshot) -> Bool {
        var a = self, b = o
        a.date = .distantPast; b.date = .distantPast
        return a == b && Calendar.current.isDate(date, inSameDayAs: o.date)
    }

    /// On a new day before the app has opened, yesterday's numbers no longer apply.
    func adjusted(for now: Date) -> WidgetSnapshot {
        guard !Calendar.current.isDate(date, inSameDayAs: now) else { return self }
        var s = self
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        if !(doneToday && Calendar.current.isDate(date, inSameDayAs: yesterday)) { s.streak = 0 }
        s.doneToday = false
        s.shotsToday = 0
        s.workoutTitle = "Today's workout"
        s.workoutMinutes = 0
        s.exerciseCount = 0
        return s
    }
}
