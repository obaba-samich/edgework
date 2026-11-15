import ActivityKit
import Foundation

/// Starts, updates and ends the Lock Screen / Dynamic Island activity for workouts and GPS runs.
@MainActor
enum LiveActivity {
    private static var current: ActivityKit.Activity<EdgeworkActivityAttributes>?
    private static var lastState: EdgeworkActivityAttributes.ContentState?

    static func show(_ state: EdgeworkActivityAttributes.ContentState, enabled: Bool) {
        guard enabled, ActivityAuthorizationInfo().areActivitiesEnabled else { return end() }
        guard state != lastState else { return }
        lastState = state
        let content = ActivityContent(state: state, staleDate: staleDate(for: state))
        if let a = current, a.activityState == .active {
            Task { await a.update(content) }
        } else {
            let accent: UInt32 = Theme.sport == .track ? 0xFF6B5E : 0x7CD4FF
            current = try? ActivityKit.Activity.request(attributes: EdgeworkActivityAttributes(name: "Edgework", accent: accent),
                                            content: content, pushType: nil)
        }
    }

    /// If the app gets killed without a chance to clean up, the activity switches to "tap to reopen" around here
    /// instead of showing a timer that will never move on.
    private static func staleDate(for s: EdgeworkActivityAttributes.ContentState) -> Date? {
        if s.paused { return nil }
        if s.kind == .run { return Date().addingTimeInterval(10 * 60) }
        if let end = s.timerEnd { return end.addingTimeInterval(3 * 60) }
        return Date().addingTimeInterval(20 * 60)
    }

    static func end() {
        lastState = nil
        let a = current
        current = nil
        Task {
            await a?.end(nil, dismissalPolicy: .immediate)
            // Clean up anything left over from a previous launch.
            for old in ActivityKit.Activity<EdgeworkActivityAttributes>.activities { await old.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// Called as the app is being closed. Waits (briefly) for the activities to end, since the process is about to go away.
    nonisolated static func endAllBeforeExit() {
        let done = DispatchSemaphore(value: 0)
        Task.detached {
            for a in ActivityKit.Activity<EdgeworkActivityAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) }
            done.signal()
        }
        _ = done.wait(timeout: .now() + 2)
    }
}
