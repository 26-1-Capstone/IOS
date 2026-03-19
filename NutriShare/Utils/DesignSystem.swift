import SwiftUI

/// NutriShare Design System — Color, Font, Spacing tokens
extension Color {
    // Brand Colors
    static let nsPrimary = Color(hex: "FFA62F")
    static let nsPrimaryLight = Color(hex: "FFC96F")
    static let nsPrimaryDark = Color(hex: "E5952A")
    static let nsPrimaryBg = Color(hex: "FFE8C8")

    static let nsSecondary = Color(hex: "ACD793")
    static let nsSecondaryLight = Color(hex: "C2E2A8")
    static let nsSecondaryDark = Color(hex: "97C081")

    // Semantic
    static let nsSuccess = Color(hex: "ACD793")
    static let nsError = Color(hex: "FF6B6B")
    static let nsWarning = Color(hex: "FFA62F")
    static let nsInfo = Color(hex: "4DABF7")

    // Neutral
    static let nsGray50 = Color(hex: "FAFAFA")
    static let nsGray100 = Color(hex: "F5F5F5")
    static let nsGray200 = Color(hex: "EEEEEE")
    static let nsGray300 = Color(hex: "E0E0E0")
    static let nsGray400 = Color(hex: "BDBDBD")
    static let nsGray500 = Color(hex: "9E9E9E")
    static let nsGray600 = Color(hex: "757575")
    static let nsGray700 = Color(hex: "616161")
    static let nsGray800 = Color(hex: "424242")
    static let nsGray900 = Color(hex: "212121")

    // Background
    static let nsBg = Color(hex: "FAFAF8")
    static let nsSurface = Color.white
    static let nsSurfaceAlt = Color(hex: "F5F5F0")

    // Text
    static let nsTextPrimary = Color(hex: "1A1A1A")
    static let nsTextSecondary = Color(hex: "555555")
    static let nsTextDisabled = Color(hex: "AAAAAA")

    // Border
    static let nsBorder = Color(hex: "E0E0E0")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Spacing

enum NSSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

// MARK: - Radius

enum NSRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Font Size

enum NSFont {
    static let xs: CGFloat = 11
    static let sm: CGFloat = 13
    static let base: CGFloat = 15
    static let md: CGFloat = 16
    static let lg: CGFloat = 18
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 30
}
