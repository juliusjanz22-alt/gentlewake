import SwiftUI

/// Clean, minimalist design system: warm off-white canvas, white cards with
/// hairline separation, near-black text, and a single warm accent. Every
/// token adapts to dark mode (neutral dark, not the old night theme) so the
/// app stays comfortable at bedtime and honors system appearance.
enum Theme {
    // Canvas
    static let bgBase = Color(light: 0xF4F2EE, dark: 0x121212)
    static let sheetBackground = Color(light: 0xF4F2EE, dark: 0x121212)

    // Surfaces (cards, pills)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1E1E1D)
    static let surfaceStroke = Color(light: 0x000000, dark: 0xFFFFFF).opacity(0.07)
    static let track = Color(light: 0xE9E6E1, dark: 0x2C2C2B)
    static let cardShadow = Color(light: 0x000000, dark: 0x000000)

    // Accent — a warm sunrise orange, used sparingly
    static let accent = Color(light: 0xF5842A, dark: 0xFF9346)
    static let accentDeep = Color(light: 0xE06E15, dark: 0xE8722A)
    static let accentBright = Color(light: 0xF5842A, dark: 0xFFB176)
    static let accentSoft = Color(light: 0xF5842A, dark: 0xFF9346).opacity(0.14)

    // Near-black control fill for active pills (the reference's dark segment)
    static let controlActive = Color(light: 0x1B1A18, dark: 0xF4F3F1)
    static let onControlActive = Color(light: 0xFFFFFF, dark: 0x1B1A18)

    // Text
    static let textPrimary = Color(light: 0x1B1A18, dark: 0xF4F3F1)
    static let textSecondary = Color(light: 0x9A9691, dark: 0x8C8984)

    // Status
    static let success = Color(light: 0x34B36B, dark: 0x45C97D)
    static let warning = Color(light: 0xE0851F, dark: 0xF0A24A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Appearance-adaptive color from two hex values.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

// MARK: - Card styling

extension View {
    /// The standard soft card: white surface, generous rounding, a hairline
    /// edge, and a low, wide shadow for gentle lift on the off-white canvas.
    func card(cornerRadius: CGFloat = 24, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
            )
            .shadow(color: Theme.cardShadow.opacity(0.05), radius: 14, x: 0, y: 6)
    }
}
