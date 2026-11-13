import SwiftUI
import MapKit
import CoreLocation
import AVFoundation

struct RunPoint: Codable, Hashable {
    var lat: Double
    var lon: Double
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }
}

/// A GPS-tracked run: route, distance and per-unit splits.
struct RunTrack: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var duration: TimeInterval
    var distanceKm: Double
    var points: [RunPoint]
    var splits: [TimeInterval]
    var splitMiles: Bool

    var paceSecPerUnit: Double {
        let units = splitMiles ? distanceKm * 0.621371 : distanceKm
        return units > 0.01 ? duration / units : 0
    }
}

// MARK: - Tracker

@MainActor
final class RunTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    enum State { case idle, running, paused, autoPaused }

    @Published var state = State.idle
    @Published var meters: Double = 0
    @Published var points: [CLLocation] = []
    @Published var splits: [TimeInterval] = []
    @Published var now = Date()
    @Published var denied = false
    @Published var accuracy: Double?

    var autoPause = true
    var announce = true
    var miles = true
    var liveActivity = true

    private let manager = CLLocationManager()
    private let speech = AVSpeechSynthesizer()
    private var startDate: Date?
    private var pausedTotal: TimeInterval = 0
    private var pausedAt: Date?
    private var lastSplitAt: TimeInterval = 0
    private var slowSince: Date?
    private var timer: Timer?

    var unitMeters: Double { miles ? 1609.344 : 1000 }
    var unitName: String { miles ? "mi" : "km" }

    var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        let end = pausedAt ?? now
        return max(0, end.timeIntervalSince(startDate) - pausedTotal)
    }

    var distanceUnits: Double { meters / unitMeters }

    /// Pace over the last ~30 seconds of movement, seconds per unit.
    var currentPace: Double? {
        guard let last = points.last else { return nil }
        guard let from = points.last(where: { last.timestamp.timeIntervalSince($0.timestamp) >= 30 }) else { return averagePace }
        let d = last.distance(from: from)
        let t = last.timestamp.timeIntervalSince(from.timestamp)
        guard d > 15 else { return nil }
        return t / (d / unitMeters)
    }

    var averagePace: Double? { distanceUnits > 0.02 ? elapsed / distanceUnits : nil }

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
        manager.pausesLocationUpdatesAutomatically = false
    }

    func prepare() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .denied, .restricted: denied = true
        default: manager.startUpdatingLocation()
        }
    }

    func start() {
        guard state == .idle else { return }
        meters = 0; points = []; splits = []; pausedTotal = 0; pausedAt = nil; lastSplitAt = 0
        startDate = Date()
        now = Date()
        state = .running
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }
        manager.startUpdatingLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        UIApplication.shared.isIdleTimerDisabled = true
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers, .mixWithOthers])
        say("Run started.")
        sync()
    }

    func pause(auto: Bool = false) {
        guard state == .running else { return }
        pausedAt = Date()
        state = auto ? .autoPaused : .paused
        if !auto { say("Paused.") }
        sync()
    }

    func resume() {
        guard state == .paused || state == .autoPaused else { return }
        if let p = pausedAt { pausedTotal += Date().timeIntervalSince(p) }
        pausedAt = nil
        state = .running
        slowSince = nil
        sync()
    }

    func finish() -> RunTrack? {
        guard state != .idle, let startDate else { return nil }
        if pausedAt == nil { pausedAt = Date() }
        let duration = elapsed
        timer?.invalidate()
        timer = nil
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        UIApplication.shared.isIdleTimerDisabled = false
        LiveActivity.end()
        state = .idle
        // Keep the saved route small: at most ~600 points.
        let stride = max(1, points.count / 600)
        let route = points.enumerated().filter { $0.offset % stride == 0 || $0.offset == points.count - 1 }
            .map { RunPoint(lat: $0.element.coordinate.latitude, lon: $0.element.coordinate.longitude) }
        let dist = String(format: "%.2f", distanceUnits)
        say("Run complete. \(dist) \(miles ? "miles" : "kilometers").")
        return RunTrack(date: startDate, duration: duration, distanceKm: meters / 1000, points: route, splits: splits, splitMiles: miles)
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        manager.stopUpdatingLocation()
        UIApplication.shared.isIdleTimerDisabled = false
        LiveActivity.end()
        state = .idle
    }

    private func tick() {
        now = Date()
        if state == .running, autoPause, let s = slowSince, Date().timeIntervalSince(s) > 10 {
            pause(auto: true)
        }
        if Int(elapsed) % 15 == 0 { sync() }
    }

    private func say(_ text: String) {
        guard announce else { return }
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.52
        speech.speak(u)
    }

    static func pace(_ secs: Double?) -> String {
        guard let s = secs, s.isFinite, s > 0, s < 3600 else { return "--:--" }
        return Int(s.rounded()).clock
    }

    private func sync() {
        typealias S = EdgeworkActivityAttributes.ContentState
        var s = S(kind: .run, title: state == .running ? "Running" : (state == .autoPaused ? "Auto-paused" : "Paused"),
                  detail: "Pace \(Self.pace(currentPace ?? averagePace)) /\(unitName)")
        s.timerStart = state == .running ? Date().addingTimeInterval(-elapsed) : nil
        s.paused = state != .running
        s.pausedText = Int(elapsed).clock
        s.value = String(format: "%.2f", distanceUnits)
        s.unit = unitName
        s.progress = distanceUnits.truncatingRemainder(dividingBy: 1)
        LiveActivity.show(s, enabled: liveActivity)
    }

    // MARK: Location

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .denied, .restricted: self.denied = true
            case .authorizedWhenInUse, .authorizedAlways:
                self.denied = false
                manager.startUpdatingLocation()
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.handle(locations) }
    }

    private func handle(_ locations: [CLLocation]) {
        for loc in locations {
            accuracy = loc.horizontalAccuracy
            guard loc.horizontalAccuracy >= 0, loc.horizontalAccuracy < 30, abs(loc.timestamp.timeIntervalSinceNow) < 10 else { continue }
            let moving = loc.speed < 0 || loc.speed > 0.7
            if state == .autoPaused && moving && loc.speed > 1.0 { resume() }
            if state == .running {
                slowSince = moving ? nil : (slowSince ?? Date())
            }
            guard state == .running else { continue }
            if let last = points.last {
                let d = loc.distance(from: last)
                let dt = loc.timestamp.timeIntervalSince(last.timestamp)
                // Ignore GPS jumps faster than a world-class sprint.
                if dt > 0 && d / dt < 12 { meters += d }
            }
            points.append(loc)
            let done = Int(meters / unitMeters)
            if done > splits.count {
                let split = elapsed - lastSplitAt
                lastSplitAt = elapsed
                splits.append(split)
                say("\(done) \(miles ? (done == 1 ? "mile" : "miles") : (done == 1 ? "kilometer" : "kilometers")). Split \(Int(split) / 60) \(Int(split) % 60).")
                sync()
            }
        }
    }
}

// MARK: - Screen

struct GPSRunView: View {
    @EnvironmentObject var store: Store
    @StateObject private var tracker = RunTracker()
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var saved: RunTrack?
    @State private var confirmEnd = false

    private let color = Color(hex: 0x22D3EE)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                map
                stats
                controls
                if !tracker.splits.isEmpty { splitsCard(tracker.splits, miles: tracker.miles) }
                if tracker.denied {
                    Label("Location is off for Edgework. Turn it on in Settings › Privacy › Location Services.", systemImage: "location.slash")
                        .font(.footnote).foregroundStyle(Theme.amber)
                }
                history
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("GPS Run")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let st = store.data.settings
            tracker.autoPause = st.gpsAutoPause
            tracker.announce = st.gpsAnnounce
            tracker.miles = st.units == .imperial
            tracker.liveActivity = st.liveActivities
            tracker.prepare()
        }
        .confirmationDialog("Finish this run?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("Save run") { save() }
            Button("Discard", role: .destructive) { tracker.cancel() }
            Button("Keep going", role: .cancel) {}
        }
        .sheet(item: $saved) { run in
            NavigationStack { RunDetailView(run: run) }.environmentObject(store)
        }
    }

    private var map: some View {
        Map(position: $camera) {
            UserAnnotation()
            if tracker.points.count > 1 {
                MapPolyline(coordinates: tracker.points.map(\.coordinate))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls { MapUserLocationButton() }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(alignment: .topLeading) {
            if let a = tracker.accuracy {
                Label(a < 15 ? "GPS good" : (a < 30 ? "GPS ok" : "Weak GPS"), systemImage: "location.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(a < 15 ? Theme.green : Theme.amber)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .padding(10)
            }
        }
    }

    private var stats: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.2f", tracker.distanceUnits)).font(.number(64, .heavy)).foregroundStyle(Theme.text)
                    .contentTransition(.numericText())
                Text(tracker.unitName).font(.title3.weight(.semibold)).foregroundStyle(Theme.text2)
                Spacer()
                if tracker.state == .autoPaused { Chip(text: "Auto-paused", symbol: "pause.fill", color: Theme.amber) }
            }
            HStack {
                stat(Int(tracker.elapsed).clock, "Time")
                stat(RunTracker.pace(tracker.currentPace), "Pace /\(tracker.unitName)")
                stat(RunTracker.pace(tracker.averagePace), "Avg /\(tracker.unitName)")
            }
        }
        .cardStyle()
    }

    private func stat(_ v: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.number(22)).foregroundStyle(Theme.text)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var controls: some View {
        switch tracker.state {
        case .idle:
            Button { tracker.start() } label: { Label("Start run", systemImage: "play.fill") }
                .buttonStyle(PrimaryButtonStyle(color: color))
                .disabled(tracker.denied)
        case .running:
            HStack(spacing: 10) {
                Button { tracker.pause() } label: { Label("Pause", systemImage: "pause.fill") }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.amber))
                Button { confirmEnd = true } label: { Label("Finish", systemImage: "flag.checkered") }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.green))
            }
        case .paused, .autoPaused:
            HStack(spacing: 10) {
                Button { tracker.resume() } label: { Label("Resume", systemImage: "play.fill") }
                    .buttonStyle(PrimaryButtonStyle(color: color))
                Button { confirmEnd = true } label: { Label("Finish", systemImage: "flag.checkered") }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.green))
            }
        }
    }

    private func splitsCard(_ splits: [TimeInterval], miles: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Overline("Splits")
            let best = splits.min() ?? 0
            ForEach(Array(splits.enumerated()), id: \.offset) { i, s in
                HStack {
                    Text("\(miles ? "Mile" : "Km") \(i + 1)").font(.subheadline).foregroundStyle(Theme.text2)
                    Spacer()
                    Text(Int(s.rounded()).clock).font(.number(16)).foregroundStyle(s == best ? Theme.green : Theme.text)
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var history: some View {
        if !store.data.runs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Overline("Recent GPS runs")
                ForEach(store.data.runs.prefix(10)) { r in
                    NavigationLink { RunDetailView(run: r) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.date.formatted(.dateTime.weekday().month().day())).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                                Text("\(Int(r.duration).clock) · \(RunTracker.pace(r.paceSecPerUnit)) /\(r.splitMiles ? "mi" : "km")")
                                    .font(.caption).foregroundStyle(Theme.text2)
                            }
                            Spacer()
                            Text(store.distanceText(r.distanceKm)).font(.number(16)).foregroundStyle(Theme.text)
                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Theme.text3)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardStyle()
        }
    }

    private func save() {
        guard let run = tracker.finish() else { return }
        guard run.distanceKm > 0.05 || run.duration > 60 else { return }
        store.data.runs.insert(run, at: 0)
        store.logManual(activity: .run, title: "GPS run", date: run.date, minutes: max(1, Int(run.duration / 60)),
                        distanceKm: run.distanceKm, rpe: 6, note: "", entries: [])
        store.notify(.success)
        saved = run
    }
}

struct RunDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let run: RunTrack

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if run.points.count > 1 {
                    Map(initialPosition: .automatic) {
                        MapPolyline(coordinates: run.points.map(\.coordinate))
                            .stroke(Color(hex: 0x22D3EE), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        if let s = run.points.first { Marker("Start", systemImage: "flag", coordinate: s.coordinate).tint(.green) }
                        if let e = run.points.last { Marker("Finish", systemImage: "flag.checkered", coordinate: e.coordinate).tint(.red) }
                    }
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                }
                HStack {
                    StatTile(value: store.distanceText(run.distanceKm), label: "Distance", symbol: "point.topleft.down.to.point.bottomright.curvepath.fill", color: Color(hex: 0x22D3EE))
                    StatTile(value: Int(run.duration).clock, label: "Time", symbol: "stopwatch.fill", color: Theme.amber)
                    StatTile(value: RunTracker.pace(run.paceSecPerUnit), label: "Pace /\(run.splitMiles ? "mi" : "km")", symbol: "speedometer", color: Theme.green)
                }
                if !run.splits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Overline("Splits")
                        let best = run.splits.min() ?? 0
                        ForEach(Array(run.splits.enumerated()), id: \.offset) { i, s in
                            HStack {
                                Text("\(run.splitMiles ? "Mile" : "Km") \(i + 1)").font(.subheadline).foregroundStyle(Theme.text2)
                                Spacer()
                                Text(Int(s.rounded()).clock).font(.number(16)).foregroundStyle(s == best ? Theme.green : Theme.text)
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle(run.date.formatted(.dateTime.weekday(.wide).month().day()))
        .navigationBarTitleDisplayMode(.inline)
    }
}
