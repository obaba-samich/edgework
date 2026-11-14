import SwiftUI

// MARK: - Shareable image cards (Instagram / TikTok / Messages)

struct ShareStat: Hashable {
    var value: String
    var label: String
}

enum ShareFormat: String, CaseIterable, Identifiable {
    case story, post
    var id: String { rawValue }
    var title: String { self == .story ? "Story 9:16" : "Post 4:5" }
    var size: CGSize { self == .story ? CGSize(width: 360, height: 640) : CGSize(width: 360, height: 450) }
}

/// The image itself. Pure data in, so it renders the same in the app and in ImageRenderer.
struct ShareCard: View {
    var overline: String
    var title: String
    var subtitle: String = ""
    var symbol: String
    var accent: Color
    var stats: [ShareStat]
    var streak: Int = 0
    var extra: AnyView? = nil
    var format: ShareFormat = .story
    var date = Date()

    private var story: Bool { format == .story }

    var body: some View {
        VStack(alignment: .leading, spacing: story ? 16 : 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold))
                Text(overline.uppercased()).font(.system(size: 13, weight: .heavy)).tracking(1.2)
                Spacer()
                Text(date.formatted(.dateTime.month(.abbreviated).day())).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text2)
            }
            .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.display(story ? 46 : 38)).foregroundStyle(Theme.text)
                    .lineLimit(2).minimumScaleFactor(0.5)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.text2).lineLimit(3)
                }
            }

            if let extra {
                extra.frame(maxWidth: .infinity, maxHeight: story ? 230 : 140)
            }

            Spacer(minLength: 0)

            statGrid

            if streak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.amber)
                    Text("\(streak)-day streak").font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.text)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: Theme.sport == .track ? "figure.run" : "figure.hockey")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(accent))
                VStack(alignment: .leading, spacing: 0) {
                    Text("EDGEWORK").font(.display(19)).foregroundStyle(Theme.text)
                    Text("Free training app").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.text2)
                }
                Spacer()
            }
        }
        .padding(story ? 28 : 22)
        .frame(width: format.size.width, height: format.size.height)
        .background(
            ZStack {
                Theme.bg
                RadialGradient(colors: [accent.opacity(0.38), .clear], center: .topTrailing, startRadius: 10, endRadius: 420)
                LinearGradient(colors: [.clear, Color.black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            }
        )
    }

    private var statGrid: some View {
        let rows = stride(from: 0, to: stats.count, by: 2).map { Array(stats[$0..<min($0 + 2, stats.count)]) }
        return VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { s in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.value).font(.number(story ? 28 : 24, .heavy)).foregroundStyle(Theme.text)
                                .lineLimit(1).minimumScaleFactor(0.5)
                            Text(s.label.uppercased()).font(.system(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(Theme.text2)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
                    }
                    if row.count == 1 { Color.clear.frame(maxWidth: .infinity) }
                }
            }
        }
    }
}

/// Preview + share button. `card` builds the card for a format.
struct ShareCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let card: (ShareFormat) -> ShareCard

    @State private var format = ShareFormat.story
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Format", selection: $format) {
                    ForEach(ShareFormat.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                if let image {
                    Image(uiImage: image)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
                        .frame(maxHeight: .infinity)
                    ShareLink(item: Image(uiImage: image), preview: SharePreview(title, image: Image(uiImage: image))) {
                        Label("Share image", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Text("Post it to your story, or Save Image to your photos.").font(.caption).foregroundStyle(Theme.text3)
                } else {
                    ProgressView().frame(maxHeight: .infinity)
                }
            }
            .padding(16)
            .screenBackground()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear(perform: render)
            .onChange(of: format) { _, _ in render() }
        }
    }

    @MainActor private func render() {
        let r = ImageRenderer(content: card(format).environment(\.colorScheme, .dark))
        r.scale = 3
        image = r.uiImage
    }
}

/// Small bar chart of values (lower is better when `lowerIsBetter`), used on hill cards.
struct ShareBars: View {
    let values: [Double]
    let color: Color

    var body: some View {
        let top = values.max() ?? 1
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", v)).font(.number(11)).foregroundStyle(Theme.text2)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(i == values.firstIndex(of: values.min() ?? 0) ? Theme.green : color)
                        .frame(height: max(8, 150 * v / top))
                    Text("\(i + 1)").font(.number(11)).foregroundStyle(Theme.text3)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Cards for each screen

extension Store {
    /// Streak including today, counting a workout you're about to save.
    func streakIncludingToday(pending: Bool) -> Int {
        pending && sessions(on: Date()).isEmpty ? currentStreak + 1 : currentStreak
    }

    func weekCard(_ format: ShareFormat) -> ShareCard {
        let week = Day.week(of: Date())
        let sessions = week.flatMap { self.sessions(on: $0) }
        let minutes = sessions.reduce(0) { $0 + $1.minutes }
        var stats = [ShareStat(value: "\(sessions.count)", label: "Workouts this week"),
                     ShareStat(value: minutes >= 120 ? String(format: "%.1fh", Double(minutes) / 60) : "\(minutes)m", label: "Training time")]
        if data.settings.sport == .hockey {
            let shots = week.reduce(0) { $0 + daily($1).totalShots }
            stats.append(ShareStat(value: "\(shots)", label: "Shots this week"))
        } else {
            stats.append(ShareStat(value: String(format: "%.1f km", weekRunKm), label: "Run this week"))
        }
        stats.append(ShareStat(value: "\(bestStreak)", label: "Best streak"))
        return ShareCard(overline: "My training", title: currentStreak > 0 ? "\(currentStreak)-day streak" : "This week",
                         subtitle: "Training every day with Edgework.", symbol: "chart.bar.xaxis", accent: Theme.ice,
                         stats: stats, extra: AnyView(WeekDots(store: self)), format: format)
    }
}

/// Seven dots for this week, filled on days you trained.
private struct WeekDots: View {
    let store: Store
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Day.week(of: Date()), id: \.self) { d in
                let done = !store.sessions(on: d).isEmpty
                VStack(spacing: 6) {
                    Circle().fill(done ? Theme.ice : Color.white.opacity(0.08))
                        .overlay(Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy)).foregroundStyle(Theme.bg).opacity(done ? 1 : 0))
                        .frame(width: 34, height: 34)
                    Text(d.formatted(.dateTime.weekday(.narrow))).font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.text2)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}
