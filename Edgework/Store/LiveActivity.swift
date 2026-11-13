import ActivityKit
import Foundation

/// Starts, updates and ends the Lock Screen / Dynamic Island activity for workouts and GPS runs.
@MainActor
enum LiveActivity {
    private static var current: Activity<EdgeworkActivityAttributes>?
    private static var lastState: EdgeworkActivityAttributes.ContentState?

    static func show(_ state: EdgeworkActivityAttributes.ContentState, enabled: Bool) {
        guard enabled, ActivityAuthorizationInfo().areActivitiesEnabled else { return end() }
        guard state != lastState else { return }
        lastState = state
        let content = ActivityContent(state: state, staleDate: nil)
        if let a = current, a.activityState == .active {
            Task { await a.update(content) }
        } else {
            let accent: UInt32 = Theme.sport == .track ? 0xFF6B5E : 0x7CD4FF
            current = try? Activity.request(attributes: EdgeworkActivityAttributes(name: "Edgework", accent: accent),
                                            content: content, pushType: nil)
        }
    }

    static func end() {
        lastState = nil
        let a = current
        current = nil
        Task {
            await a?.end(nil, dismissalPolicy: .immediate)
            // Clean up anything left over from a previous launch.
            for old in Activity<EdgeworkActivityAttributes>.activities { await old.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
