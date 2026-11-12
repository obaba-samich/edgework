import SwiftUI
import UIKit

enum Theme {
    /// Set by the store whenever the sport changes. Track tints the app warm red; hockey stays ice blue.
    static var sport = Sport.hockey
    private static var track: Bool { sport == .track }

    static var bg: Color { track ? Color(hex: 0x100A0C) : Color(hex: 0x080D18) }
    static var surface: Color { track ? Color(hex: 0x1C1316) : Color(hex: 0x111827) }
    static var surface2: Color { track ? Color(hex: 0x271B1F) : Color(hex: 0x1A2335) }
    static let stroke = Color.white.opacity(0.07)
    static let text = Color(hex: 0xEDF2FA)
    static var text2: Color { track ? Color(hex: 0xB0979C) : Color(hex: 0x8D99B2) }
    static var text3: Color { track ? Color(hex: 0x7A6266) : Color(hex: 0x5A6680) }
    static var ice: Color { track ? Color(hex: 0xFF8A7A) : Color(hex: 0x7CD4FF) }
    static var iceDeep: Color { track ? Color(hex: 0xE5484D) : Color(hex: 0x2F8CFF) }
    static let red = Color(hex: 0xFF4D5E)
    static let green = Color(hex: 0x3DDC97)
    static let amber = Color(hex: 0xFFB547)
    static let radius: CGFloat = 20
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension Font {
    static func display(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }

    static func number(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

enum Appearance {
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.bg)
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.text),
            .font: UIFont.systemFont(ofSize: 34, weight: .heavy, width: .condensed),
        ]
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.text),
            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.bg)
        tab.shadowColor = UIColor.white.withAlphaComponent(0.06)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

extension View {
    func screenBackground() -> some View {
        background(Theme.bg.ignoresSafeArea())
    }

    func cardStyle(padding: CGFloat = 16, fill: Color = Theme.surface) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.stroke))
    }
}
