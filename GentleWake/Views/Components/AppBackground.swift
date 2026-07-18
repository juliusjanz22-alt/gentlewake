import SwiftUI

/// The app canvas: a flat warm off-white (neutral dark in dark mode) with a
/// single, barely-there warm highlight near the top for depth. Deliberately
/// quiet — the content and its soft cards carry the design.
struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.bgBase

            RadialGradient(
                colors: [Theme.accent.opacity(0.06), .clear],
                center: UnitPoint(x: 0.5, y: -0.1),
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
