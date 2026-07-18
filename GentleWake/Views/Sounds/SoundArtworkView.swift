import SwiftUI

/// Placeholder card artwork: a soft pastel tint derived from the sound's
/// stable hue with its symbol as the motif, in a tonal (deeper same-hue)
/// color. The reference app uses illustrated scenes here — these swap for
/// real artwork at final branding.
struct SoundArtworkView: View {
    let sound: AlarmSound

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hue: sound.artHue, saturation: 0.28, brightness: 0.95),
                        Color(hue: (sound.artHue + 0.06).truncatingRemainder(dividingBy: 1), saturation: 0.40, brightness: 0.86),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: sound.symbol)
                    .font(.system(size: geo.size.width * 0.32, weight: .light))
                    .foregroundStyle(Color(hue: sound.artHue, saturation: 0.55, brightness: 0.45))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Grid cell: square artwork with the name in a dark capsule near the bottom,
/// matching the reference layout. Selection = accent border + checkmark.
struct SoundCardView: View {
    let sound: AlarmSound
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SoundArtworkView(sound: sound)
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .bottom) {
                    Text(sound.name)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.surface.opacity(0.9), in: Capsule())
                        .padding(.bottom, 10)
                        .padding(.horizontal, 6)
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, Theme.accent)
                            .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            isSelected ? Theme.accent : Theme.surfaceStroke,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sound.name)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint("Sets this as your alarm sound")
    }
}
