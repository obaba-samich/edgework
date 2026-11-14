import SwiftUI
import WidgetKit

extension Store {
    /// Refreshes the Home Screen widgets when what they show has changed.
    func syncWidgets() {
        let today = data.today?.workout
        let next = upcomingEvents.first { kind($0) == .game }
        let hockey = data.settings.sport == .hockey
        let snap = WidgetSnapshot(date: Date(),
                                  workoutTitle: today?.title ?? "Today's workout",
                                  workoutMinutes: today.map(estimateMinutes) ?? 0,
                                  exerciseCount: today?.items.count ?? 0,
                                  doneToday: !sessions(on: Date()).isEmpty,
                                  streak: currentStreak,
                                  shotsToday: daily().totalShots,
                                  shotGoal: data.settings.shotGoal,
                                  hockey: hockey,
                                  accent: hockey ? 0x7CD4FF : 0xFF8A7A,
                                  nextEvent: next?.title,
                                  nextEventDate: next?.start)
        if snap.save() { WidgetCenter.shared.reloadAllTimelines() }
    }
}
