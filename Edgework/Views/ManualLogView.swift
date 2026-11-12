import SwiftUI

/// Log something done outside the app: a run, a skate, a game, a gym session.
struct ManualLogView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var activity = Activity.run
    @State private var title = ""
    @State private var date = Date()
    @State private var minutes = 30
    @State private var distance = ""
    @State private var rpe = 6
    @State private var note = ""
    @State private var entries: [SessionEntry] = []
    @State private var picking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                        ForEach(Activity.allCases) { a in
                            Button { activity = a; hideKeyboard() } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: a.symbol).font(.system(size: 18, weight: .semibold)).frame(height: 22)
                                    Text(a.title).font(.system(size: 12, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(activity == a ? Theme.bg : Theme.text)
                                .frame(maxWidth: .infinity)
                                .frame(height: 62)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(activity == a ? Theme.ice : Theme.surface2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section {
                    TextField("Name (optional)", text: $title).submitLabel(.done)
                    DatePicker("When", selection: $date, in: ...Date())
                    Stepper("Duration: \(minutes) min", value: $minutes, in: 5...300, step: 5)
                    if activity.hasDistance {
                        HStack {
                            Text("Distance")
                            Spacer()
                            TextField("0.0", text: $distance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("km").foregroundStyle(Theme.text2)
                        }
                    }
                }
                .listRowBackground(Theme.surface)

                Section("Effort: \(rpe)/10") {
                    Slider(value: Binding(get: { Double(rpe) }, set: { rpe = Int($0.rounded()) }), in: 1...10, step: 1)
                        .tint(rpe >= 8 ? Theme.red : (rpe >= 6 ? Theme.amber : Theme.green))
                }
                .listRowBackground(Theme.surface)

                Section {
                    ForEach($entries, id: \.exerciseID) { $e in
                        if let ex = Library.byID[e.exerciseID] {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(ex.name).font(.subheadline.weight(.semibold))
                                HStack {
                                    Stepper("\(e.sets) sets", value: $e.sets, in: 1...20).font(.footnote)
                                }
                                Stepper("\(ex.measure.format(e.value))\(ex.measure == .reps ? " reps" : "")", value: $e.value, in: 1...5000,
                                        step: ex.measure == .reps ? 1 : 5)
                                    .font(.footnote)
                            }
                        }
                    }
                    .onDelete { entries.remove(atOffsets: $0) }
                    Button { picking = true } label: { Label("Add exercises you did", systemImage: "plus.circle.fill") }
                } header: { Text("Exercises (optional)") } footer: {
                    Text("Added exercises count toward your muscle map and history.")
                }
                .listRowBackground(Theme.surface)

                Section("Notes") {
                    TextField("How did it go?", text: $note, axis: .vertical).lineLimit(2...5)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .screenBackground()
            .navigationTitle("Log activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let km = Double(distance.replacingOccurrences(of: ",", with: "."))
                        store.logManual(activity: activity, title: title, date: date, minutes: minutes,
                                        distanceKm: activity.hasDistance ? km : nil, rpe: rpe, note: note, entries: entries)
                        store.notify(.success)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $picking) {
                ExercisePicker { picked in
                    for ex in picked where !entries.contains(where: { $0.exerciseID == ex.id }) {
                        entries.append(SessionEntry(exerciseID: ex.id, sets: ex.sets, value: ex.base, measure: ex.measure))
                    }
                }
                .environmentObject(store)
            }
        }
    }
}
