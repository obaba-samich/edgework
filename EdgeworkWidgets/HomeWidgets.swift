import SwiftUI
import WidgetKit

private extension Color {
    init(rgb: UInt32) {
        self.init(red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }
    static let edgeBG = Color(red: 0.03, green: 0.05, blue: 0.09)
    static let edgeText2 = Color(red: 0.55, green: 0.6, blue: 0.7)
    static let flame = Color(red: 1, green: 0.71, blue: 0.28)
    static let done = Color(red: 0.24, green: 0.86, blue: 0.59)
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snap: WidgetSnapshot
    let ready: Bool
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry { SnapshotEntry(date: Date(), snap: .placeholder, ready: true) }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(entry(at: Date(), preview: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
        // One entry now and one at midnight, so a new day resets the numbers even if the app isn't opened.
        completion(Timeline(entries: [entry(at: now, preview: false), entry(at: midnight.addingTimeInterval(1), preview: false)],
                            policy: .after(midnight.addingTimeInterval(3600))))
    }

    private func entry(at date: Date, preview: Bool) -> SnapshotEntry {
        if let s = WidgetSnapshot.load() { return SnapshotEntry(date: date, snap: s.adjusted(for: date), ready: true) }
        return SnapshotEntry(date: date, snap: .placeholder, ready: preview)
    }
}

// MARK: - Today widget

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EdgeworkToday", provider: SnapshotProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.edgeBG }
                .widgetURL(URL(string: "edgework://today"))
        }
        .configurationDisplayName("Today")
        .description("Today's workout, your streak and shots.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry
    private var s: WidgetSnapshot { entry.snap }
    private var accent: Color { Color(rgb: s.accent) }
    private var shotProgress: Double { min(1, Double(s.shotsToday) / Double(max(1, s.shotGoal))) }

    var body: some View {
        if !entry.ready {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "figure.hockey").foregroundStyle(accent)
                Text("Open Edgework to set up this widget.").font(.caption).foregroundStyle(.white)
            }
        } else {
            switch family {
            case .accessoryInline:
                Text(s.doneToday ? "✓ Trained · \(s.streak)-day streak" : "\(s.workoutTitle) · \(s.streak)🔥")
            case .accessoryCircular:
                if s.hockey {
                    Gauge(value: shotProgress) { Image(systemName: "target") } currentValueLabel: { Text("\(s.shotsToday)") }
                        .gaugeStyle(.accessoryCircular)
                } else {
                    VStack(spacing: 0) {
                        Image(systemName: "flame.fill")
                        Text("\(s.streak)").font(.headline)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text(s.doneToday ? "Trained today ✓" : s.workoutTitle).font(.headline).lineLimit(1)
                    Text(s.workoutMinutes > 0 && !s.doneToday ? "\(s.workoutMinutes) min · \(s.exerciseCount) exercises" : "\(s.streak)-day streak")
                        .font(.caption).lineLimit(1)
                    if s.hockey { Text("\(s.shotsToday)/\(s.shotGoal) shots").font(.caption).lineLimit(1) }
                }
            case .systemMedium:
                HStack(spacing: 14) {
                    workoutBlock
                    Divider().overlay(Color.white.opacity(0.1))
                    VStack(alignment: .leading, spacing: 10) {
                        streakRow
                        if s.hockey { shotsBlock }
                        if let e = s.nextEvent, let d = s.nextEventDate {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("NEXT").font(.system(size: 9, weight: .heavy)).foregroundStyle(Color.edgeText2)
                                Text(e).font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                                Text(d, style: .relative).font(.caption2).foregroundStyle(Color.edgeText2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            default:
                VStack(alignment: .leading, spacing: 8) {
                    workoutBlock
                    Spacer(minLength: 0)
                    streakRow
                    if s.hockey { shotsBar }
                }
            }
        }
    }

    private var workoutBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: s.doneToday ? "checkmark.circle.fill" : (s.hockey ? "figure.hockey" : "figure.run"))
                Text(s.doneToday ? "DONE" : "TODAY").font(.system(size: 11, weight: .heavy))
            }
            .foregroundStyle(s.doneToday ? Color.done : accent)
            Text(s.workoutTitle).font(.system(size: 20, weight: .heavy).width(.condensed)).foregroundStyle(.white)
                .lineLimit(2).minimumScaleFactor(0.7)
            if s.workoutMinutes > 0 {
                Text("\(s.workoutMinutes) min · \(s.exerciseCount) ex").font(.caption).foregroundStyle(Color.edgeText2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var streakRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill").foregroundStyle(Color.flame)
            Text("\(s.streak)").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text("day streak").font(.caption2).foregroundStyle(Color.edgeText2)
        }
    }

    private var shotsBar: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(s.shotsToday)/\(s.shotGoal) shots").font(.caption2.weight(.semibold)).foregroundStyle(Color.edgeText2)
            ProgressView(value: shotProgress).tint(accent)
        }
    }

    private var shotsBlock: some View {
        HStack(spacing: 8) {
            Gauge(value: shotProgress) { EmptyView() } currentValueLabel: {
                Text("\(s.shotsToday)").font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(accent)
            .scaleEffect(0.8)
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text("Shots").font(.caption.weight(.semibold)).foregroundStyle(.white)
                Text("goal \(s.shotGoal)").font(.caption2).foregroundStyle(Color.edgeText2)
            }
        }
    }
}
