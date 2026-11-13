import SwiftUI
import Charts

// MARK: - Track events

struct TrackEventDef: Identifiable, Hashable {
    let id: String
    let name: String
    let isTime: Bool

    static let all: [TrackEventDef] = [
        .init(id: "60", name: "60 m", isTime: true), .init(id: "100", name: "100 m", isTime: true),
        .init(id: "200", name: "200 m", isTime: true), .init(id: "400", name: "400 m", isTime: true),
        .init(id: "800", name: "800 m", isTime: true), .init(id: "1600", name: "1600 m", isTime: true),
        .init(id: "3200", name: "3200 m", isTime: true), .init(id: "100h", name: "100 m Hurdles", isTime: true),
        .init(id: "110h", name: "110 m Hurdles", isTime: true), .init(id: "300h", name: "300 m Hurdles", isTime: true),
        .init(id: "400h", name: "400 m Hurdles", isTime: true), .init(id: "lj", name: "Long Jump", isTime: false),
        .init(id: "tj", name: "Triple Jump", isTime: false), .init(id: "hj", name: "High Jump", isTime: false),
        .init(id: "pv", name: "Pole Vault", isTime: false), .init(id: "sp", name: "Shot Put", isTime: false),
        .init(id: "dt", name: "Discus", isTime: false), .init(id: "jt", name: "Javelin", isTime: false),
    ]
    static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}

enum TrackFormat {
    /// 12.34 or 1:58.20
    static func time(_ s: Double) -> String {
        s >= 60 ? String(format: "%d:%05.2f", Int(s) / 60, s.truncatingRemainder(dividingBy: 60)) : String(format: "%.2f", s)
    }

    static func parseTime(_ text: String) -> Double? {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: ":")
        if parts.count == 2, let m = Double(parts[0]), let s = Double(parts[1]) { return m * 60 + s }
        return Double(text)
    }

    static func mark(_ meters: Double, imperial: Bool) -> String {
        guard imperial else { return String(format: "%.2f m", meters) }
        let inches = meters / 0.0254
        return String(format: "%d' %.1f\"", Int(inches) / 12, inches.truncatingRemainder(dividingBy: 12))
    }
}

// MARK: - PRs

struct TrackPRsView: View {
    @EnvironmentObject var store: Store
    @State private var logging: TrackEventDef?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("Track & Field")
                    Text("Personal Records").font(.display(32)).foregroundStyle(Theme.text)
                }
                ForEach(ordered) { ev in
                    prRow(ev, mine: store.data.settings.trackEvents.contains(ev.id))
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $logging) { ev in LogMarkSheet(event: ev).environmentObject(store) }
    }

    private var ordered: [TrackEventDef] {
        let mine = store.data.settings.trackEvents
        return TrackEventDef.all.filter { mine.contains($0.id) } + TrackEventDef.all.filter { !mine.contains($0.id) }
    }

    @ViewBuilder
    private func prRow(_ ev: TrackEventDef, mine isMine: Bool) -> some View {
        let entries = store.data.trackPRs.filter { $0.event == ev.id }.sorted { $0.date < $1.date }
        let best = ev.isTime ? entries.map(\.value).min() : entries.map(\.value).max()
        Button { logging = ev } label: {
            HStack(spacing: 12) {
                IconBadge(symbol: ev.isTime ? "stopwatch.fill" : "ruler.fill", color: Theme.ice, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(ev.name).font(.headline).foregroundStyle(Theme.text)
                        if isMine { Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(Theme.amber) }
                    }
                    Text(entries.isEmpty ? "No marks yet" : "\(entries.count) logged").font(.caption).foregroundStyle(Theme.text2)
                }
                Spacer()
                if entries.count >= 2 {
                    Chart(entries) { e in
                        LineMark(x: .value("Date", e.date), y: .value("Mark", e.value)).foregroundStyle(Theme.ice)
                    }
                    .chartXAxis(.hidden).chartYAxis(.hidden)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(width: 60, height: 28)
                }
                Text(best.map { format(ev, $0) } ?? "—").font(.number(17)).foregroundStyle(best == nil ? Theme.text3 : Theme.text)
            }
            .cardStyle(padding: 12)
        }
        .buttonStyle(PressableStyle())
    }

    private func format(_ ev: TrackEventDef, _ v: Double) -> String {
        guard ev.isTime else { return TrackFormat.mark(v, imperial: store.data.settings.units == .imperial) }
        // Hand times run fast; +0.24 s is the usual conversion for sprints up to 400 m.
        let sprint = ["60", "100", "200", "400", "100h", "110h", "300h", "400h"].contains(ev.id)
        if store.data.settings.handTimed && sprint { return TrackFormat.time(v) + "h" }
        return TrackFormat.time(v)
    }
}

struct TrackEventsPicker: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            Section {
                ForEach(TrackEventDef.all) { ev in
                    let on = store.data.settings.trackEvents.contains(ev.id)
                    Button {
                        if on { store.data.settings.trackEvents.removeAll { $0 == ev.id } } else { store.data.settings.trackEvents.append(ev.id) }
                    } label: {
                        HStack {
                            Text(ev.name).foregroundStyle(Theme.text)
                            Spacer()
                            Image(systemName: on ? "checkmark.circle.fill" : "circle").foregroundStyle(on ? Theme.ice : Theme.text3)
                        }
                    }
                }
            } footer: { Text("Pick the events you compete in.") }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("My events")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LogMarkSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let event: TrackEventDef
    @State private var text = ""
    @State private var date = Date()
    @State private var note = ""

    private var imperial: Bool { store.data.settings.units == .imperial }

    private var parsed: Double? {
        if event.isTime { return TrackFormat.parseTime(text) }
        if imperial {
            // 18-6.5 or 18' 6.5 or 222 (inches)
            let cleaned = text.replacingOccurrences(of: "'", with: "-").replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: " ", with: "")
            let parts = cleaned.split(separator: "-")
            if parts.count == 2, let ft = Double(parts[0]), let inch = Double(parts[1]) { return (ft * 12 + inch) * 0.0254 }
            if let ft = Double(cleaned) { return ft * 12 * 0.0254 }
            return nil
        }
        return Double(text)
    }

    var body: some View {
        let entries = store.data.trackPRs.filter { $0.event == event.id }.sorted { $0.date > $1.date }
        NavigationStack {
            Form {
                Section {
                    TextField(event.isTime ? "12.34 or 1:58.20" : (imperial ? "18-6.5 (feet-inches)" : "6.12 (meters)"), text: $text)
                        .keyboardType(.numbersAndPunctuation)
                        .font(.number(26))
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    TextField("Meet / note (optional)", text: $note)
                } header: { Text("New mark") }
                .listRowBackground(Theme.surface)
                if !entries.isEmpty {
                    Section("History") {
                        ForEach(entries) { e in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                                    if !e.note.isEmpty { Text(e.note).font(.caption).foregroundStyle(Theme.text2) }
                                }
                                Spacer()
                                Text(event.isTime ? TrackFormat.time(e.value) : TrackFormat.mark(e.value, imperial: imperial)).font(.number(15))
                            }
                        }
                        .onDelete { idx in
                            let ids = idx.map { entries[$0].id }
                            store.data.trackPRs.removeAll { ids.contains($0.id) }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(event.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = parsed, v > 0 {
                            store.data.trackPRs.append(TrackPR(event: event.id, date: date, value: v, note: note))
                            store.notify(.success)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(parsed == nil)
                }
            }
        }
    }
}

// MARK: - Stopwatch

struct StopwatchView: View {
    @EnvironmentObject var store: Store
    @State private var startedAt: Date?
    @State private var accumulated: TimeInterval = 0
    @State private var laps: [TimeInterval] = []

    private func elapsed(_ now: Date) -> TimeInterval { accumulated + (startedAt.map { now.timeIntervalSince($0) } ?? 0) }

    var body: some View {
        VStack(spacing: 18) {
            TimelineView(.periodic(from: .now, by: 0.03)) { tl in
                let t = elapsed(tl.date)
                VStack(spacing: 6) {
                    Text(TrackFormat.time(t)).font(.number(64, .heavy)).foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity)
                    if let last = laps.last {
                        Text("Lap \(laps.count + 1): \(TrackFormat.time(t - last))").font(.number(18)).foregroundStyle(Theme.text2)
                    }
                }
            }
            .padding(.top, 20)

            HStack(spacing: 14) {
                Button {
                    if startedAt != nil {
                        laps.append(elapsed(Date()))
                        store.haptic(.light)
                    } else {
                        accumulated = 0
                        laps = []
                    }
                } label: { Text(startedAt != nil ? "Lap" : "Reset").frame(width: 100) }
                    .buttonStyle(SecondaryButtonStyle())
                Button {
                    if let s = startedAt {
                        accumulated += Date().timeIntervalSince(s)
                        startedAt = nil
                    } else {
                        startedAt = Date()
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                    store.haptic(.medium)
                } label: { Text(startedAt != nil ? "Stop" : "Start") }
                    .buttonStyle(PrimaryButtonStyle(color: startedAt != nil ? Theme.red : Theme.green))
            }

            List {
                ForEach(Array(laps.enumerated().reversed()), id: \.offset) { i, total in
                    let split = total - (i > 0 ? laps[i - 1] : 0)
                    HStack {
                        Text("Lap \(i + 1)").foregroundStyle(Theme.text2)
                        Spacer()
                        Text(TrackFormat.time(split)).font(.number(16)).foregroundStyle(Theme.text)
                        Text(TrackFormat.time(total)).font(.number(13)).foregroundStyle(Theme.text3).frame(width: 80, alignment: .trailing)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .padding(16)
        .screenBackground()
        .navigationTitle("Stopwatch")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

// MARK: - Pace calculator

struct PaceCalculatorView: View {
    @State private var distance = 1600.0
    @State private var timeText = "6:00"

    private let presets: [Double] = [100, 200, 400, 800, 1600, 3200, 5000]

    private var seconds: Double? { TrackFormat.parseTime(timeText) }

    var body: some View {
        Form {
            Section {
                Picker("Distance", selection: $distance) {
                    ForEach(presets, id: \.self) { d in Text(d >= 1000 ? String(format: "%.1f km", d / 1000) : "\(Int(d)) m").tag(d) }
                }
                HStack {
                    Text("Time")
                    Spacer()
                    TextField("6:00 or 52.3", text: $timeText)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .font(.number(18))
                }
            } header: { Text("Race or goal") }
            .listRowBackground(Theme.surface)

            if let s = seconds, s > 0 {
                Section("Pace") {
                    row("Per 100 m", s / distance * 100)
                    row("Per 200 m", s / distance * 200)
                    row("Per 400 m lap", s / distance * 400)
                    row("Per km", s / distance * 1000)
                    row("Per mile", s / distance * 1609.34)
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text(String(format: "%.2f m/s · %.1f mph", distance / s, distance / s * 2.23694)).font(.number(15))
                    }
                }
                .listRowBackground(Theme.surface)

                if distance >= 400 {
                    Section("Lap splits") {
                        let laps = Int((distance / 400).rounded(.up))
                        ForEach(1...laps, id: \.self) { lap in
                            let d = min(distance, Double(lap) * 400)
                            row(d >= 1000 ? String(format: "%.1f km", d / 1000) : "\(Int(d)) m", s / distance * d)
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Pace Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ s: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(TrackFormat.time(s)).font(.number(16))
        }
    }
}

// MARK: - Sport switcher

struct SportMenu: View {
    @EnvironmentObject var store: Store

    var body: some View {
        Menu {
            ForEach(Sport.allCases) { s in
                Button { withAnimation { store.setSport(s) } } label: {
                    if s == store.data.settings.sport { Label(s.title, systemImage: "checkmark") } else { Label(s.title, systemImage: s.symbol) }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: store.data.settings.sport.symbol)
                Text(store.data.settings.sport.title)
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.ice)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(Theme.ice.opacity(0.14)))
        }
    }
}
