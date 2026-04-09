import SwiftUI
import UIKit

// MARK: - Hex initialisers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (255, 255, 255)
        }
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, alpha: 1)
    }

    /// Returns a dynamic color that switches between light and dark variants.
    static func adaptive(light: String, dark: String) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        }
    }
}

// MARK: - ReceiptSnap Palette (adaptive light / dark)

extension Color {
    // Background
    static let rsBackgroundGreen = Color(UIColor.adaptive(light: "F6FBF7", dark: "0D1A12"))

    // Chips, tags, subtle fills
    static let rsLightGreen      = Color(UIColor.adaptive(light: "D7E7DD", dark: "1C3528"))

    // Success accent — unchanged in both modes
    static let rsMediumGreen     = Color(hex: "5FB88A")

    // Primary buttons, links — stays readable on dark bg
    static let rsForestGreen     = Color(hex: "1F6F54")

    // Headings / dark text in light; becomes a light mint in dark
    static let rsDeepGreen       = Color(UIColor.adaptive(light: "0E3B2E", dark: "7ECFAA"))

    // Text
    static let rsTextPrimary     = Color(UIColor.adaptive(light: "111827", dark: "F3F4F6"))
    static let rsTextSecondary   = Color(UIColor.adaptive(light: "6B7280", dark: "C4CDD8"))
    static let rsTextMuted       = Color(UIColor.adaptive(light: "9CA3AF", dark: "8A9BAA"))

    // System / semantic
    static let rsError           = Color(hex: "EF4444")
    static let rsSuccess         = Color(hex: "10B981")

    // Borders, dividers, input backgrounds
    static let rsBorder          = Color(UIColor.adaptive(light: "E5E7EB", dark: "2A3D32"))
    static let rsInputBackground = Color(UIColor.adaptive(light: "F9FAFB", dark: "132B1E"))
    static let rsDivider         = Color(UIColor.adaptive(light: "F3F4F6", dark: "1C3528"))

    // Nav / header bar background
    static let rsBackgroundBar   = Color(UIColor.adaptive(light: "F6FBF7", dark: "091510"))

    // Card / surface background (white in light, dark surface in dark mode)
    static let rsCardBackground  = Color(UIColor.systemBackground)
}
