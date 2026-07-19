import SwiftUI

/// Consistent marker for features that aren't built yet: a small lock pill.
/// Use `LockBadge()` inline, or `.locked()` to mark an entire row/card as
/// unavailable (dims it, adds the badge, and blocks interaction).
struct LockBadge: View {
    var text: String = "Soon"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
            Text(text)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.track, in: Capsule())
        .accessibilityElement()
        .accessibilityLabel("Locked, coming soon")
    }
}

private struct LockedModifier: ViewModifier {
    var badgeText: String

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                LockBadge(text: badgeText)
                    .padding(10)
            }
            .opacity(0.55)
            .allowsHitTesting(false)
            .accessibilityHint("Not available yet")
    }
}

extension View {
    /// Marks a row/card as not-yet-available: dimmed, non-interactive, with a
    /// lock badge in the corner.
    func locked(_ badgeText: String = "Soon") -> some View {
        modifier(LockedModifier(badgeText: badgeText))
    }
}
