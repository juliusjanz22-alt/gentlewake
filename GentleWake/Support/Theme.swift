import SwiftUI

/// Color roles and shared styling sampled from the reference screenshots.
/// Names describe roles, not source-app branding.
enum Theme {
    // Background
    static let bgBase = Color(hex: 0x0C0714)
    static let bgGlow = Color(hex: 0x2A1B4A)

    // Surfaces (pills, cards, sheets)
    static let surface = Color.white.opacity(0.06)
    static let surfaceStroke = Color.white.opacity(0.10)
    static let sheetBackground = Color(hex: 0x140C22)

    // Accent (the purple glow family)
    static let accentDeep = Color(hex: 0x4F35C4)
    static let accent = Color(hex: 0x8B67F7)
    static let accentBright = Color(hex: 0xC9B8FF)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xA79BC2)

    // Status
    static let success = Color(hex: 0x4CD97B)
    static let warning = Color(hex: 0xF5A75A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
