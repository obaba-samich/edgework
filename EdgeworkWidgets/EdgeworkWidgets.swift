import ActivityKit
import SwiftUI
import WidgetKit

@main
struct EdgeworkWidgets: WidgetBundle {
    var body: some Widget {
        EdgeworkLiveActivity()
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

struct EdgeworkLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EdgeworkActivityAttributes.self) { context in
            LockScreenView(state: context.state, accent: Color(hex: context.attributes.accent))
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(Color(hex: context.attributes.accent))
        } dynamicIsland: { context in
            let s = context.state
            let accent = Color(hex: context.attributes.accent)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: symbol(s))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: s)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(s.kind == .rest ? Color.white : accent)
                        .frame(maxWidth: 110, alignment: .trailing)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(s.title).font(.headline).lineLimit(1)
                        Text(s.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !s.value.isEmpty {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(s.value).font(.system(size: 22, weight: .bold, design: .rounded)).monospacedDigit()
                            Text(s.unit).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    }
                    ProgressView(value: max(0, min(1, s.progress)))
                        .tint(accent)
                        .padding(.horizontal, 8)
                }
            } compactLeading: {
                Image(systemName: symbol(s)).foregroundStyle(accent)
            } compactTrailing: {
                TimerText(state: s)
                    .monospacedDigit()
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: symbol(s)).foregroundStyle(accent)
            }
            .keylineTint(accent)
        }
    }
}

private func symbol(_ s: EdgeworkActivityAttributes.ContentState) -> String {
    if s.paused { return "pause.fill" }
    switch s.kind {
    case .workout: return "figure.strengthtraining.functional"
    case .rest: return "timer"
    case .run: return "figure.run"
    }
}

/// Counts down to the end of a set or rest, or up from the start of a run. Updates on its own.
struct TimerText: View {
    let state: EdgeworkActivityAttributes.ContentState

    var body: some View {
        if state.paused {
            Text(state.pausedText.isEmpty ? "Paused" : state.pausedText)
        } else if let end = state.timerEnd, end > Date() {
            Text(timerInterval: Date()...end, countsDown: true)
                .multilineTextAlignment(.trailing)
        } else if let start = state.timerStart {
            Text(start, style: .timer)
                .multilineTextAlignment(.trailing)
        } else {
            Text("Go")
        }
    }
}

struct LockScreenView: View {
    let state: EdgeworkActivityAttributes.ContentState
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol(state))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(accent.opacity(0.18)))
            VStack(alignment: .leading, spacing: 3) {
                Text(state.title).font(.headline).foregroundStyle(.white).lineLimit(1)
                Text(state.detail).font(.subheadline).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                ProgressView(value: max(0, min(1, state.progress))).tint(accent)
            }
            VStack(alignment: .trailing, spacing: 2) {
                TimerText(state: state)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(maxWidth: 110, alignment: .trailing)
                if !state.value.isEmpty {
                    Text("\(state.value) \(state.unit)").font(.caption.weight(.semibold)).foregroundStyle(accent)
                }
            }
        }
        .padding(16)
    }
}
