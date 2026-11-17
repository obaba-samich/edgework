import CoreImage.CIFilterBuiltins
import SwiftUI
import VisionKit

// MARK: - Link format

/// Workouts travel as `edgework://w?d=<zlib + base64url JSON>`. No server; the whole workout is in the link.
enum WorkoutLink {
    private struct Compact: Codable {
        var v = 1
        var t: String
        var s: String
        var f: Focus
        var i: [Item]
    }

    private struct Item: Codable {
        var e: String
        var n: Int
        var b: Int
        var r: Int
        var k: Block
        var x: Bool?
    }

    static func url(for w: Workout) -> URL? {
        let c = Compact(t: w.title, s: w.subtitle, f: w.focus,
                        i: w.items.map { Item(e: $0.exerciseID, n: $0.sets, b: $0.base, r: $0.rest, k: $0.block, x: $0.fixed ? true : nil) })
        guard let json = try? JSONEncoder().encode(c),
              let packed = try? (json as NSData).compressed(using: .zlib) as Data else { return nil }
        let b64 = packed.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        return URL(string: "edgework://w?d=\(b64)")
    }

    /// Accepts the link itself or any text that contains one (pasted messages, QR payloads).
    static func workout(from text: String) -> (workout: Workout, dropped: Int)? {
        guard let r = text.range(of: "edgework://w?d=") else { return nil }
        let tail = text[r.upperBound...].prefix { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        var b64 = tail.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b64.count % 4 != 0 { b64 += "=" }
        guard let packed = Data(base64Encoded: b64),
              let json = try? (packed as NSData).decompressed(using: .zlib) as Data,
              let c = try? JSONDecoder().decode(Compact.self, from: json) else { return nil }
        let known = c.i.filter { Library.byID[$0.e] != nil }
        let items = known.map { WorkoutItem(exerciseID: $0.e, sets: max(1, min($0.n, 20)), base: max(1, $0.b), rest: max(0, min($0.r, 600)),
                                            block: $0.k, fixed: $0.x ?? false) }
        guard !items.isEmpty else { return nil }
        return (Workout(title: String(c.t.prefix(60)), subtitle: String(c.s.prefix(200)), focus: c.f, items: items), c.i.count - known.count)
    }

    static func qr(_ string: String) -> UIImage? {
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(string.utf8)
        f.correctionLevel = "M"
        guard let out = f.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cg = CIContext().createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Share a workout

struct WorkoutShareSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let workout: Workout
    @State private var copied = false
    @State private var showCard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let url = WorkoutLink.url(for: workout) {
                        VStack(spacing: 10) {
                            if let img = WorkoutLink.qr(url.absoluteString) {
                                Image(uiImage: img).interpolation(.none).resizable().scaledToFit()
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
                                    .frame(maxWidth: 280)
                            }
                            Text(workout.title).font(.display(24)).foregroundStyle(Theme.text)
                            Text("\(store.estimateMinutes(workout)) min · \(workout.items.count) exercises").font(.subheadline).foregroundStyle(Theme.text2)
                            Text("Teammates scan this with the iPhone Camera, or in Edgework under Train › My workouts › Scan.")
                                .font(.caption).foregroundStyle(Theme.text3).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .cardStyle()

                        ShareLink(item: url, subject: Text(workout.title),
                                  message: Text("Try my workout \"\(workout.title)\" in Edgework. Tap the link to import it.")) {
                            Label("Send link", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            UIPasteboard.general.string = url.absoluteString
                            copied = true
                            store.haptic(.light)
                        } label: { Label(copied ? "Copied" : "Copy link", systemImage: copied ? "checkmark" : "doc.on.doc") }
                            .buttonStyle(SecondaryButtonStyle())

                        Button { showCard = true } label: { Label("Share as image with QR", systemImage: "photo") }
                            .buttonStyle(SecondaryButtonStyle())
                    } else {
                        EmptyState(symbol: "exclamationmark.triangle", title: "Couldn't make a link", message: "Try again after editing the workout.")
                    }
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Share workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showCard) {
                ShareCardSheet(title: workout.title) { fmt in workoutCard(fmt) }
            }
        }
    }

    private func workoutCard(_ fmt: ShareFormat) -> ShareCard {
        let names = workout.ordered.filter { $0.block == .main || $0.block == .finisher }.compactMap { $0.exercise?.name }
        let qr = WorkoutLink.url(for: workout).flatMap { WorkoutLink.qr($0.absoluteString) }
        return ShareCard(overline: "Try my workout", title: workout.title,
                         subtitle: names.prefix(fmt == .story ? 6 : 3).joined(separator: " · "),
                         symbol: workout.focus.symbol, accent: workout.focus.color,
                         stats: [ShareStat(value: "\(store.estimateMinutes(workout)) min", label: "Time"),
                                 ShareStat(value: "\(workout.items.count)", label: "Exercises")],
                         extra: qr.map { img in
                             AnyView(VStack(spacing: 6) {
                                 Image(uiImage: img).interpolation(.none).resizable().scaledToFit()
                                     .padding(8).background(RoundedRectangle(cornerRadius: 12).fill(.white))
                                 Text("Scan to import").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.text2)
                             })
                         },
                         format: fmt)
    }
}

// MARK: - Import

struct WorkoutImportSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var workout: Workout
    @State private var saved = false

    var body: some View {
        NavigationStack {
            WorkoutDetailView(workout: $workout)
                .navigationTitle("Shared workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            var w = workout
                            w.id = UUID()
                            store.saveCustom(w)
                            store.notify(.success)
                            dismiss()
                        }
                        .fontWeight(.bold)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        let w = store.withMustDos(workout)
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { store.start(w) }
                    } label: { Label("Start now", systemImage: "play.fill") }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(16)
                }
        }
    }
}

/// Scan a workout QR code, or paste a link.
struct WorkoutScanView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    BarcodeScanner { code in handle(code) }
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .frame(maxHeight: .infinity)
                    Text("Point at a workout QR code.").font(.subheadline).foregroundStyle(Theme.text2)
                } else {
                    EmptyState(symbol: "qrcode.viewfinder", title: "Camera scanning isn't available",
                               message: "Scan the code with the iPhone Camera app instead, or paste the link below.")
                        .frame(maxHeight: .infinity)
                }
                Button {
                    handle(UIPasteboard.general.string ?? "")
                } label: { Label("Paste link", systemImage: "doc.on.clipboard") }
                    .buttonStyle(SecondaryButtonStyle())
                if let error { Text(error).font(.footnote).foregroundStyle(Theme.red) }
            }
            .padding(16)
            .screenBackground()
            .navigationTitle("Import workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func handle(_ text: String) {
        guard let result = WorkoutLink.workout(from: text) else {
            error = "That isn't an Edgework workout link."
            return
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { store.pendingImport = result.workout }
    }
}
