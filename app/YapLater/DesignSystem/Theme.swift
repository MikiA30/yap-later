import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Yap Later's look: warm paper, dark ink, one loud brand color, and a color per category.
/// Views take every color, size, and radius from here.
enum Theme {
    // MARK: Color

    static let paper = Color(light: 0xFFF4E4, dark: 0x16131C)
    static let card = Color(light: 0xFFFFFF, dark: 0x231F2C)
    /// The warm wash at the top of the page, behind the greeting.
    static let wash = Color(light: 0xFFDDB5, dark: 0x40242F)
    static let ink = Color(light: 0x1B1722, dark: 0xFFF4E4)
    static let inkSoft = Color(light: 0x6F6878, dark: 0xA79FB2)
    /// The solid "edge" under cards and buttons that gives them depth.
    static let edge = Color(light: 0x1B1722, dark: 0x000000)
    static let brand = Color(light: 0xFF5A2B, dark: 0xFF6A3D)
    static let brandEdge = Color(light: 0xC73A12, dark: 0xB8370F)
    static let lemon = Color(light: 0xFFD23F, dark: 0xFFD23F)
    /// A budget that is running low.
    static let warning = Color(light: 0xF2A100, dark: 0xFFB627)
    static let danger = Color(light: 0xE5383B, dark: 0xFF5A5F)
    static let onBrand = Color.white

    static func color(for category: Category) -> Color {
        switch category {
        case .groceries: Color(light: 0x1FA85F, dark: 0x35D07F)
        case .dining: Color(light: 0xF57C00, dark: 0xFF9A2E)
        case .coffee: Color(light: 0xA85B2A, dark: 0xD08A55)
        case .transport: Color(light: 0x2166E8, dark: 0x5B95FF)
        case .shopping: Color(light: 0xE83E8C, dark: 0xFF6FB0)
        case .bills: Color(light: 0x5146D8, dark: 0x8E86FF)
        case .fun: Color(light: 0x9333EA, dark: 0xB974FF)
        case .health: Color(light: 0x0E9F94, dark: 0x2ED3C6)
        case .other: Color(light: 0x6B7280, dark: 0x9CA3AF)
        }
    }

    // MARK: Shape and space

    enum Radius {
        static let chip: CGFloat = 12
        static let card: CGFloat = 22
        static let sheet: CGFloat = 30
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    /// How far a pressable thing sits above its edge.
    static let depth: CGFloat = 5

    // MARK: Type

    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .black, design: .rounded) }
    static let title = Font.system(.title3, design: .rounded, weight: .heavy)
    static let headline = Font.system(.headline, design: .rounded, weight: .heavy)
    static let body = Font.system(.body, design: .rounded, weight: .semibold)
    static let caption = Font.system(.caption, design: .rounded, weight: .bold)
    static let label = Font.system(.caption2, design: .rounded, weight: .heavy)
}

extension Color {
    /// A color that follows light and dark mode, from two hex values.
    init(light: UInt32, dark: UInt32) {
        func parts(_ hex: UInt32) -> (CGFloat, CGFloat, CGFloat) {
            (CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255)
        }
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            let (red, green, blue) = parts(traits.userInterfaceStyle == .dark ? dark : light)
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        })
        #else
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let (red, green, blue) = parts(isDark ? dark : light)
            return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
        })
        #endif
    }
}
