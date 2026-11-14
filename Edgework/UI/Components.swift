import SwiftUI

struct Overline: View {
    let text: String
    var color: Color = Theme.text2

    init(_ text: String, color: Color = Theme.text2) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(color)
    }
}

struct SectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.display(22, .bold)).foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(Theme.text2)
                }
            }
            Spacer()
            trailing
        }
        .padding(.top, 6)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
    }
}

struct IconBadge: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(color.opacity(0.14))
            )
    }
}

struct Chip: View {
    let text: String
    var symbol: String? = nil
    var color: Color = Theme.text2
    var filled = false

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.system(size: 11, weight: .bold)) }
            Text(text).font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(filled ? Theme.bg : color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(filled ? color : color.opacity(0.12)))
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var symbol: String? = nil
    var color: Color = Theme.ice

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 14, weight: .bold)).foregroundStyle(color)
                    .frame(height: 18)
            }
            Text(value).font(.number(26)).foregroundStyle(Theme.text)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.caption.weight(.medium)).foregroundStyle(Theme.text2)
        }
        .cardStyle(padding: 14)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.ice

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(color))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = Theme.text

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface2))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct RoundIconButton: View {
    let symbol: String
    var size: CGFloat = 34
    var color: Color = Theme.text
    var fill: Color = Theme.surface2
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(Circle().fill(fill))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
    }
}

/// − value + control used everywhere a target can be tuned.
struct TargetStepper: View {
    let value: String
    var unit: String? = nil
    var tint: Color = Theme.text
    let minus: () -> Void
    let plus: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            RoundIconButton(symbol: "minus", size: 30, action: minus)
            VStack(spacing: 0) {
                Text(value).font(.number(17)).foregroundStyle(tint)
                if let unit {
                    Text(unit).font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.text3)
                }
            }
            .frame(minWidth: 44)
            RoundIconButton(symbol: "plus", size: 30, action: plus)
        }
    }
}

struct Ring: View {
    let progress: Double
    var color: Color = Theme.ice
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct LevelDots: View {
    let level: Int
    var color: Color = Theme.ice

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Capsule().fill(i <= level ? color : Theme.text3.opacity(0.4)).frame(width: 10, height: 4)
            }
        }
    }
}

/// Thin stacked bar showing what a workout is made of.
struct CompositionBar: View {
    let categories: [Category]

    var body: some View {
        let counts = Dictionary(grouping: categories, by: { $0 }).mapValues(\.count)
        let ordered = Category.allCases.filter { counts[$0] != nil }
        let total = max(1, categories.count)
        GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(ordered) { c in
                    Capsule().fill(c.color)
                        .frame(width: max(4, (geo.size.width - CGFloat(ordered.count - 1) * 3) * CGFloat(counts[c] ?? 0) / CGFloat(total)))
                }
            }
        }
        .frame(height: 6)
    }
}

struct ExerciseRowLabel: View {
    let exercise: Exercise
    var trailing: String? = nil
    var showFavorite = false
    var priority = 0
    var required = false

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: exercise.symbol, color: exercise.category.color, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(exercise.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.text)
                        .lineLimit(1)
                    if showFavorite {
                        Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(Theme.amber)
                    }
                    if required {
                        Image(systemName: "checklist").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.red)
                    }
                    if priority != 0 {
                        HStack(spacing: 1) {
                            ForEach(0..<abs(priority), id: \.self) { _ in
                                Image(systemName: priority > 0 ? "chevron.up" : "chevron.down").font(.system(size: 8, weight: .black))
                            }
                        }
                        .foregroundStyle(priority > 0 ? Theme.green : Theme.amber)
                    }
                }
                Text(exercise.primary.map(\.title).joined(separator: " · "))
                    .font(.footnote).foregroundStyle(Theme.text2).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 5) {
                if let trailing {
                    Text(trailing).font(.number(13, .semibold)).foregroundStyle(Theme.text2)
                }
                LevelDots(level: exercise.level, color: exercise.category.color)
            }
        }
        .contentShape(Rectangle())
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 34, weight: .semibold)).foregroundStyle(Theme.text3)
            Text(title).font(.headline).foregroundStyle(Theme.text)
            Text(message).font(.subheadline).foregroundStyle(Theme.text2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardStyle()
    }
}

extension Int {
    var clock: String { String(format: "%d:%02d", self / 60, self % 60) }
}

/// Seven steps from Rarely to Max, Normal in the middle.
struct PriorityPicker: View {
    @Binding var value: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(Store.priorityLevels, id: \.self) { p in
                    Button { value = p } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(p == value ? color(p) : Theme.surface2)
                            Image(systemName: p == 0 ? "circle.fill" : (p > 0 ? "chevron.up" : "chevron.down"))
                                .font(.system(size: p == 0 ? 7 : 11, weight: .black))
                                .foregroundStyle(p == value ? Theme.bg : color(p).opacity(0.5 + 0.15 * Double(abs(p))))
                        }
                        .frame(height: 34)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(Store.priorityName(p))
                    .accessibilityAddTraits(p == value ? .isSelected : [])
                }
            }
            HStack {
                Text("Rarely").font(.caption2).foregroundStyle(Theme.text3)
                Spacer()
                Text(Store.priorityName(value)).font(.caption.weight(.bold)).foregroundStyle(color(value))
                Spacer()
                Text("Max").font(.caption2).foregroundStyle(Theme.text3)
            }
        }
    }

    private func color(_ p: Int) -> Color { p > 0 ? Theme.green : (p < 0 ? Theme.amber : Theme.text2) }
}
