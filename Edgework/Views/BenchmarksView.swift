import SwiftUI
import Charts

struct BenchmarksView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Combine Tests").font(.display(32)).foregroundStyle(Theme.text)
                    Text("Test every 4–6 weeks, fresh, after a good warm-up. Same conditions each time so the numbers mean something.")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                }
                ForEach(Benchmark.allCases) { b in
                    NavigationLink { BenchmarkDetailView(benchmark: b) } label: { BenchmarkCard(benchmark: b) }
                        .buttonStyle(PressableStyle())
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BenchmarkCard: View {
    @EnvironmentObject var store: Store
    let benchmark: Benchmark

    var body: some View {
        let entries = store.entries(benchmark)
        let latest = entries.last
        let delta: Double? = entries.count >= 2 ? entries[entries.count - 1].value - entries[entries.count - 2].value : nil
        HStack(spacing: 12) {
            IconBadge(symbol: benchmark.symbol, color: Theme.green, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(benchmark.title).font(.headline).foregroundStyle(Theme.text)
                if let latest {
                    HStack(spacing: 6) {
                        Text("\(benchmark.format(latest.value)) \(benchmark.unit)").font(.number(15)).foregroundStyle(Theme.text2)
                        if let delta, delta != 0 {
                            let good = benchmark.lowerIsBetter ? delta < 0 : delta > 0
                            Text("\(delta > 0 ? "+" : "")\(benchmark.format(delta))")
                                .font(.number(12, .bold))
                                .foregroundStyle(good ? Theme.green : Theme.red)
                        }
                    }
                } else {
                    Text("No results yet").font(.footnote).foregroundStyle(Theme.text3)
                }
            }
            Spacer()
            if entries.count >= 2 {
                Chart(entries) { e in
                    LineMark(x: .value("Date", e.date), y: .value("Value", e.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.green)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(width: 70, height: 32)
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.text3)
        }
        .cardStyle(padding: 12)
    }
}

struct BenchmarkDetailView: View {
    @EnvironmentObject var store: Store
    let benchmark: Benchmark
    @State private var adding = false

    var body: some View {
        let entries = store.entries(benchmark)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Overline(benchmark.lowerIsBetter ? "Lower is better" : "Higher is better", color: Theme.green)
                    Text(benchmark.title).font(.display(32)).foregroundStyle(Theme.text)
                }
                HStack(spacing: 10) {
                    StatTile(value: entries.last.map { benchmark.format($0.value) } ?? "—", label: "Latest (\(benchmark.unit))", symbol: "clock.arrow.circlepath", color: Theme.ice)
                    StatTile(value: store.best(benchmark).map { benchmark.format($0) } ?? "—", label: "Best (\(benchmark.unit))", symbol: "trophy.fill", color: Theme.amber)
                }
                if entries.count >= 2 {
                    Chart(entries) { e in
                        AreaMark(x: .value("Date", e.date), y: .value("Value", e.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [Theme.green.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Date", e.date), y: .value("Value", e.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.green)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        PointMark(x: .value("Date", e.date), y: .value("Value", e.value))
                            .foregroundStyle(Theme.green)
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day()).foregroundStyle(Theme.text3)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(Theme.stroke)
                            AxisValueLabel().foregroundStyle(Theme.text3)
                        }
                    }
                    .frame(height: 200)
                    .cardStyle()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Overline("How to test")
                    Text(benchmark.how).font(.subheadline).foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle()

                Button { adding = true } label: { Label("Log a result", systemImage: "plus") }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.green))

                if !entries.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Overline("Results").padding(.bottom, 8)
                        ForEach(entries.reversed()) { e in
                            HStack {
                                Text(e.date.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(Theme.text2)
                                Spacer()
                                Text("\(benchmark.format(e.value)) \(benchmark.unit)").font(.number(16)).foregroundStyle(Theme.text)
                                Menu {
                                    Button(role: .destructive) {
                                        store.data.benchmarks.removeAll { $0.id == e.id }
                                    } label: { Label("Delete", systemImage: "trash") }
                                } label: {
                                    Image(systemName: "ellipsis").foregroundStyle(Theme.text3).frame(width: 30, height: 30)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .cardStyle()
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $adding) {
            LogBenchmarkSheet(benchmark: benchmark)
                .environmentObject(store)
        }
    }
}

struct LogBenchmarkSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let benchmark: Benchmark
    @State private var text = ""
    @State private var date = Date()
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Result", text: $text)
                            .keyboardType(.decimalPad)
                            .font(.number(28))
                            .focused($focused)
                        Text(benchmark.unit).foregroundStyle(Theme.text2)
                    }
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(benchmark.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(text.replacingOccurrences(of: ",", with: ".")) {
                            store.data.benchmarks.append(BenchmarkEntry(benchmark: benchmark, date: date, value: v))
                            store.notify(.success)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(Double(text.replacingOccurrences(of: ",", with: ".")) == nil)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
