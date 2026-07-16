import SwiftUI

/// Temporary stand-in for screens scheduled in later phases, so every
/// navigation entry point is wired from day one.
struct PlaceholderSheet: View {
    let title: String
    let phase: String

    var body: some View {
        ZStack {
            Theme.sheetBackground.ignoresSafeArea()

            VStack(spacing: 10) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("Coming in \(phase)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
