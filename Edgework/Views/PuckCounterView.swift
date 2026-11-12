import SwiftUI

/// Shoot a bucket, pick it back up, repeat until the shot goal is hit. Tracks every puck so none go missing.
struct PuckCounterView: View {
    @EnvironmentObject var store: Store

    enum Phase { case setup, shooting, pickup, done }

    @State private var phase = Phase.setup
    @State private var goal = 100
    @State private var shotType = ShotType.wrist
    @State private var shots = 0
    @State private var round = 0
    @State private var inHand = 0
    @State private var pickedUp = 0
    @State private var lost = 0
    @State private var confirmMissing = false

    private var pucks: Int { store.data.settings.puckCount }
    private var activePucks: Int { max(0, pucks - lost) }
    private var remaining: Int { max(0, goal - shots) }
    private var roundsLeft: Int { activePucks == 0 ? 0 : Int((Double(remaining) / Double(activePucks)).rounded(.up)) }
    private var thisRound: Int { min(activePucks, remaining) }
    private var outThere: Int { max(0, inHand - pickedUp) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("Shooting", color: Color(hex: 0xB8F36B))
                    Text("Puck Counter").font(.display(32)).foregroundStyle(Theme.text)
                    Text("Shoot your bucket, pick them all up, repeat until you hit your number.")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                }
                progressCard
                switch phase {
                case .setup: setup
                case .shooting: shooting
                case .pickup: pickup
                case .done: done
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if phase == .shooting || phase == .pickup {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End & log") {
                        store.addShots(shotType, shots)
                        phase = .done
                    }
                }
            }
        }
        .onAppear { if phase == .setup { goal = max(10, store.data.settings.shotGoal) } }
        .confirmationDialog("\(outThere) \(outThere == 1 ? "puck is" : "pucks are") still out there", isPresented: $confirmMissing, titleVisibility: .visible) {
            Button("Keep looking", role: .cancel) {}
            Button("They're lost, continue without them", role: .destructive) {
                lost += outThere
                finishPickup()
            }
        } message: {
            Text("Check behind the net, under the boards and in the grass.")
        }
    }

    // MARK: Pieces

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Ring(progress: Double(shots) / Double(max(1, goal)), color: Color(hex: 0xB8F36B), lineWidth: 12)
                VStack(spacing: 0) {
                    Text("\(shots)").font(.number(34, .heavy)).foregroundStyle(Theme.text).contentTransition(.numericText())
                    Text("of \(goal)").font(.caption.weight(.semibold)).foregroundStyle(Theme.text2)
                }
            }
            .frame(width: 120, height: 120)
            VStack(alignment: .leading, spacing: 8) {
                row("Shots left", "\(remaining)", Theme.text)
                row("Rounds left", "\(roundsLeft)", Theme.text)
                row("Pucks in play", "\(activePucks)", Theme.text)
                if lost > 0 { row("Lost", "\(lost)", Theme.red) }
            }
        }
        .cardStyle()
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.text2)
            Spacer()
            Text(value).font(.number(16)).foregroundStyle(color)
        }
    }

    private var setup: some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                HStack {
                    Text("Shots to take").font(.headline).foregroundStyle(Theme.text)
                    Spacer()
                    TargetStepper(value: "\(goal)", minus: { goal = max(5, goal - 5) }, plus: { goal = min(2000, goal + 5) })
                }
                HStack {
                    Text("Pucks I have").font(.headline).foregroundStyle(Theme.text)
                    Spacer()
                    TargetStepper(value: "\(pucks)", minus: { store.data.settings.puckCount = max(1, pucks - 1) },
                                  plus: { store.data.settings.puckCount = min(200, pucks + 1) })
                }
                Picker("Shot", selection: $shotType) {
                    ForEach(ShotType.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text("\(goal) shots with \(pucks) pucks = \(Int((Double(goal) / Double(max(1, pucks))).rounded(.up))) rounds")
                    .font(.footnote).foregroundStyle(Theme.text2)
            }
            .cardStyle()
            Button {
                shots = 0; round = 0; lost = 0
                startRound()
            } label: { Label("Start", systemImage: "play.fill") }
                .buttonStyle(PrimaryButtonStyle(color: Color(hex: 0xB8F36B)))
        }
    }

    private var shooting: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Overline("Round \(round) of \(round + roundsLeft - 1)", color: Color(hex: 0xB8F36B))
                Text("Shoot \(inHand)").font(.display(54)).foregroundStyle(Theme.text)
                Text(inHand < activePucks ? "Last round: only \(inHand) of your \(activePucks) pucks" : "All \(inHand) pucks")
                    .font(.subheadline).foregroundStyle(Theme.text2)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            Button {
                shots += inHand
                pickedUp = 0
                phase = .pickup
                store.notify(.success)
            } label: { Label("Shot them all", systemImage: "checkmark") }
                .buttonStyle(PrimaryButtonStyle(color: Color(hex: 0xB8F36B)))
        }
    }

    private var pickup: some View {
        VStack(spacing: 14) {
            Button {
                guard pickedUp < inHand else { return }
                pickedUp += 1
                store.haptic(pickedUp == inHand ? .heavy : .light)
                if pickedUp == inHand { store.notify(.success) }
            } label: {
                VStack(spacing: 6) {
                    Text("\(pickedUp)").font(.number(84, .heavy)).contentTransition(.numericText())
                    Text("of \(inHand) picked up").font(.headline)
                    Text(outThere == 0 ? "All found!" : "Tap for every puck you grab · \(outThere) still out")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(outThere == 0 ? Theme.bg : Theme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(outThere == 0 ? Theme.green : Theme.surface2))
            }
            .buttonStyle(PressableStyle())

            HStack(spacing: 10) {
                Button { pickedUp = max(0, pickedUp - 1) } label: { Label("Undo", systemImage: "minus") }
                    .buttonStyle(SecondaryButtonStyle())
                Button { pickedUp = inHand } label: { Label("Got them all", systemImage: "checkmark.circle") }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.green))
            }

            Button {
                if outThere > 0 { confirmMissing = true } else { finishPickup() }
            } label: { Label(remaining == 0 ? "Finish" : "Next round", systemImage: "arrow.right") }
                .buttonStyle(PrimaryButtonStyle(color: outThere == 0 ? Color(hex: 0xB8F36B) : Theme.amber))
        }
    }

    private var done: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 46)).foregroundStyle(Theme.green)
                Text("\(shots) shots done").font(.display(34)).foregroundStyle(Theme.text)
                Text(lost == 0 ? "All \(pucks) pucks accounted for." : "\(lost) \(lost == 1 ? "puck" : "pucks") lost. You have \(activePucks) left.")
                    .font(.subheadline).foregroundStyle(lost == 0 ? Theme.text2 : Theme.red)
                Text("Logged to your shot tracker.").font(.caption).foregroundStyle(Theme.text3)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            if lost > 0 {
                Button { store.data.settings.puckCount = activePucks; lost = 0 } label: {
                    Label("Update my puck count to \(activePucks)", systemImage: "pencil")
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.amber))
            }
            Button { phase = .setup } label: { Label("New session", systemImage: "arrow.counterclockwise") }
                .buttonStyle(PrimaryButtonStyle(color: Color(hex: 0xB8F36B)))
        }
    }

    // MARK: Flow

    private func startRound() {
        round += 1
        inHand = thisRound
        phase = inHand > 0 ? .shooting : .done
    }

    private func finishPickup() {
        if remaining == 0 || activePucks == 0 {
            store.addShots(shotType, shots)
            phase = .done
        } else {
            startRound()
        }
    }
}
