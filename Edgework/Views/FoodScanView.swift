import SwiftUI
import PhotosUI
import Vision

/// Reads text and barcodes out of photos with on-device Vision.
enum ImageReader {
    static func text(in image: UIImage) async -> [String] {
        guard let cg = image.cgImage else { return [] }
        let orientation = image.cgOrientation
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false
                try? VNImageRequestHandler(cgImage: cg, orientation: orientation).perform([request])
                let lines = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
                cont.resume(returning: lines)
            }
        }
    }

    static func barcode(in image: UIImage) async -> String? {
        guard let cg = image.cgImage else { return nil }
        let orientation = image.cgOrientation
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNDetectBarcodesRequest()
                try? VNImageRequestHandler(cgImage: cg, orientation: orientation).perform([request])
                cont.resume(returning: request.results?.compactMap(\.payloadStringValue).first)
            }
        }
    }
}

extension UIImage {
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}

/// Pulls calories and macros out of OCR'd nutrition-facts text.
enum LabelParser {
    struct Result {
        var serving = ""
        var kcal: Double?
        var protein: Double?
        var carbs: Double?
        var fat: Double?
        var fiber: Double?
        var found: Int { [kcal, protein, carbs, fat].compactMap { $0 }.count }
    }

    static func parse(_ lines: [String]) -> Result {
        let text = lines.joined(separator: " ").lowercased()
            .replacingOccurrences(of: "|", with: " ")
            .replacingOccurrences(of: "omg", with: "0mg")
        var r = Result()
        func number(_ pattern: String) -> Double? {
            guard let re = try? NSRegularExpression(pattern: pattern),
                  let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  m.numberOfRanges > 1, let range = Range(m.range(at: m.numberOfRanges - 1), in: text) else { return nil }
            return Double(text[range].replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: "o", with: "0"))
        }
        r.kcal = number(#"calories[^0-9]{0,20}([0-9]{1,4})"#) ?? number(#"energy[^0-9]{0,30}([0-9]{1,4})\s*kcal"#)
        r.fat = number(#"total\s*fat[^0-9]{0,6}([0-9]+(?:[.,][0-9])?)\s*g"#) ?? number(#"\bfat[^0-9]{0,6}([0-9]+(?:[.,][0-9])?)\s*g"#)
        r.carbs = number(#"carbohydrates?\.?[^0-9]{0,6}([0-9]+(?:[.,][0-9])?)\s*g"#) ?? number(#"carbs?\.?[^0-9]{0,6}([0-9]+(?:[.,][0-9])?)\s*g"#)
        r.protein = number(#"protein[^0-9]{0,6}([0-9]+(?:[.,][0-9])?)\s*g"#)
        r.fiber = number(#"fib(?:er|re)[^0-9]{0,6}([0-9]+(?:[.,][0-9])?)\s*g"#)
        if let re = try? NSRegularExpression(pattern: #"serving\s*size[:\s]*([^a-z]*[a-z0-9 ./()]{1,30}?)(?=\s+(amount|calories|servings|per)|$)"#),
           let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(m.range(at: 1), in: text) {
            r.serving = String(text[range]).trimmingCharacters(in: .whitespaces)
        }
        return r
    }
}

// MARK: - Scan screen

struct FoodScanView: View {
    enum Mode { case label, barcode }

    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let mode: Mode
    /// Called with the saved food so the caller can show it or log it.
    let onFood: (Food) -> Void

    @State private var photo: PhotosPickerItem?
    @State private var showCamera = false
    @State private var working = false
    @State private var message: String?

    @State private var name = ""
    @State private var serving = "1 serving"
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var scanned = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { showCamera = true } label: {
                        Label(mode == .label ? "Take a photo of the label" : "Take a photo of the barcode", systemImage: "camera.fill")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    PhotosPicker(selection: $photo, matching: .images) {
                        Label("Choose from photos", systemImage: "photo.on.rectangle")
                    }
                    if working { HStack { ProgressView(); Text("Reading…").foregroundStyle(Theme.text2) } }
                    if let message { Text(message).font(.footnote).foregroundStyle(Theme.amber) }
                } footer: {
                    Text(mode == .label
                         ? "Get the whole Nutrition Facts panel in frame, flat and well lit. Check the numbers before saving."
                         : "Barcodes are looked up on Open Food Facts and saved to your food library.")
                }
                .listRowBackground(Theme.surface)

                if mode == .label {
                    Section {
                        TextField("Name (required)", text: $name)
                        TextField("Serving size", text: $serving)
                        field("Calories", $kcal)
                        field("Protein (g)", $protein)
                        field("Carbs (g)", $carbs)
                        field("Fat (g)", $fat)
                        field("Fiber (g)", $fiber)
                    } header: { Text(scanned ? "Check what was read" : "Nutrition facts") }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .screenBackground()
            .navigationTitle(mode == .label ? "Scan nutrition label" : "Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                if mode == .label {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveLabel() }
                            .fontWeight(.bold)
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Double(kcal) == nil)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in Task { await handle(image) } }
                    .ignoresSafeArea()
            }
            .onChange(of: photo) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        await handle(image)
                    } else {
                        message = "Couldn't open that photo."
                    }
                    photo = nil
                }
            }
        }
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
        }
    }

    private func fmt(_ v: Double?) -> String {
        guard let v else { return "" }
        return v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v)
    }

    private func handle(_ image: UIImage) async {
        working = true
        message = nil
        defer { working = false }
        switch mode {
        case .barcode:
            guard let code = await ImageReader.barcode(in: image) else {
                message = "No barcode found in that photo."
                return
            }
            if let food = await FoodAPI.barcode(code) {
                store.saveToLibrary(food)
                dismiss()
                onFood(food)
            } else {
                message = "Barcode \(code) isn't on Open Food Facts. Scan the nutrition label instead."
            }
        case .label:
            let lines = await ImageReader.text(in: image)
            let r = LabelParser.parse(lines)
            if r.found == 0 {
                message = "Couldn't read a nutrition label. Try a closer, flatter photo, or type the numbers."
                return
            }
            if !r.serving.isEmpty { serving = r.serving }
            kcal = fmt(r.kcal); protein = fmt(r.protein); carbs = fmt(r.carbs); fat = fmt(r.fat); fiber = fmt(r.fiber)
            scanned = true
            message = r.found < 4 ? "Read \(r.found) of 4 main values. Fill in the rest." : nil
        }
    }

    private func saveLabel() {
        func n(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }
        let p = n(protein), c = n(carbs), f = n(fiber)
        var benefits: [FoodBenefit] = []
        if p >= 15 { benefits.append(.recovery) }
        if c >= 25 { benefits.append(.energy) }
        if f >= 5 { benefits.append(.gut) }
        let food = Food(id: "label-\(UUID().uuidString)", name: name.trimmingCharacters(in: .whitespaces), group: .snack,
                        serving: serving.isEmpty ? "1 serving" : serving, kcal: n(kcal), protein: p, carbs: c, fat: n(fat),
                        fiber: f, benefits: benefits, note: "", source: "My foods (label scan)")
        store.saveToLibrary(food)
        store.notify(.success)
        dismiss()
        onFood(food)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - My foods

struct MyFoodsView: View {
    @EnvironmentObject var store: Store
    @State private var scanning: FoodScanView.Mode?

    var body: some View {
        List {
            Section {
                Button { scanning = .label } label: { Label("Scan a nutrition label", systemImage: "doc.text.viewfinder") }
                Button { scanning = .barcode } label: { Label("Barcode from a photo", systemImage: "barcode") }
            } footer: { Text("Scanned labels, barcodes and quick-adds you saved live here and show up first when you search.") }
            .listRowBackground(Theme.surface)
            Section("\(store.data.customFoods.count) saved") {
                if store.data.customFoods.isEmpty { Text("Nothing saved yet.").foregroundStyle(Theme.text2) }
                ForEach(store.data.customFoods) { f in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.name).font(.subheadline.weight(.semibold))
                        Text("\(f.serving) · \(Int(f.kcal)) kcal · P \(Int(f.protein)) · C \(Int(f.carbs)) · F \(Int(f.fat))")
                            .font(.caption).foregroundStyle(Theme.text2)
                    }
                }
                .onDelete { store.data.customFoods.remove(atOffsets: $0) }
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("My Foods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(item: Binding(get: { scanning.map { ScanMode(mode: $0) } }, set: { scanning = $0?.mode })) { m in
            FoodScanView(mode: m.mode) { _ in }.environmentObject(store)
        }
    }
}

struct ScanMode: Identifiable {
    let mode: FoodScanView.Mode
    var id: String { mode == .label ? "label" : "barcode" }
}
