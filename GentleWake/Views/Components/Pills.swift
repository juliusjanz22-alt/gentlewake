import SwiftUI

/// Translucent capsule used for status chips and secondary buttons.
struct GlassPill: ViewModifier {
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Theme.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.surfaceStroke, lineWidth: 1))
    }
}

extension View {
    func glassPill(horizontalPadding: CGFloat = 16, verticalPadding: CGFloat = 10) -> some View {
        modifier(GlassPill(horizontalPadding: horizontalPadding, verticalPadding: verticalPadding))
    }
}

/// Circular translucent icon button (e.g. the profile button).
struct CircleGlassButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 42, height: 42)
                .background(Theme.surface, in: Circle())
                .overlay(Circle().strokeBorder(Theme.surfaceStroke, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }
}
