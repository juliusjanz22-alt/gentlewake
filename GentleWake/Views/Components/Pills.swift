import SwiftUI

/// Soft capsule chip: white surface, hairline edge, gentle shadow. Used for
/// status chips and secondary buttons on the off-white canvas.
struct GlassPill: ViewModifier {
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Theme.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.surfaceStroke, lineWidth: 1))
            .shadow(color: Theme.cardShadow.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func glassPill(horizontalPadding: CGFloat = 16, verticalPadding: CGFloat = 10) -> some View {
        modifier(GlassPill(horizontalPadding: horizontalPadding, verticalPadding: verticalPadding))
    }
}

/// Circular icon button (e.g. the profile button): white surface, hairline,
/// soft shadow, dark glyph.
struct CircleGlassButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 44, height: 44)
                .background(Theme.surface, in: Circle())
                .overlay(Circle().strokeBorder(Theme.surfaceStroke, lineWidth: 1))
                .shadow(color: Theme.cardShadow.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .accessibilityLabel(label)
    }
}
