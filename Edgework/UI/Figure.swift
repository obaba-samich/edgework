import SwiftUI

/// The exercise's icon tile. Demos are real videos (see DemoVideoLink) instead of drawn figures.
struct FigureView: View {
    let exercise: Exercise
    var color: Color

    init(exercise: Exercise, color: Color? = nil, animate: Bool = true, controls: Bool = true) {
        self.exercise = exercise
        self.color = color ?? exercise.category.color
    }

    var body: some View {
        Image(systemName: exercise.symbol)
            .resizable().scaledToFit()
            .padding(28)
            .foregroundStyle(color)
            .symbolRenderingMode(.hierarchical)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}

/// Opens a YouTube search for a form demo of the exercise.
struct DemoVideoLink: View {
    let exercise: Exercise
    var color: Color? = nil

    static func url(for ex: Exercise) -> URL {
        var c = URLComponents(string: "https://www.youtube.com/results")!
        let suffix = ex.category == .stickhandling ? "hockey stickhandling drill" : "exercise how to proper form"
        c.queryItems = [URLQueryItem(name: "search_query", value: "\(ex.name) \(suffix)")]
        return c.url!
    }

    var body: some View {
        let tint = color ?? exercise.category.color
        Link(destination: Self.url(for: exercise)) {
            HStack(spacing: 10) {
                Image(systemName: "play.rectangle.fill").font(.title3)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Watch a demo").font(.subheadline.weight(.semibold))
                    Text("Opens videos of \(exercise.name) on YouTube").font(.caption).foregroundStyle(Theme.text2)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption.weight(.bold))
            }
            .foregroundStyle(Theme.text)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.18)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(tint.opacity(0.35)))
        }
        .tint(tint)
    }
}
