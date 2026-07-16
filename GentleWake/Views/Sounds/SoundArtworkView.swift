import SwiftUI

/// Placeholder card artwork: a deep gradient derived from the sound's stable
/// hue with its symbol as the motif. The reference app uses illustrated
/// scenes here — these swap for real artwork at final branding.
struct SoundArtworkView: View {
    let sound: AlarmSound

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hue: sound.artHue, saturation: 0.55, brightness: 0.45),
                        Color(hue: (sound.artHue + 0.09).truncatingRemainder(dividingBy: 1), saturation: 0.65, brightness: 0.18),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: sound.symbol)
                    .font(.system(size: geo.size.width * 0.34, weight: .light))
                    .foregroundStyle(.white.opacity(0.55))
                    .shadow(color: .black.opacity(0.3), radius: 6)
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
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.55), in: Capsule())
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
                            isSelected ? Theme.accentBright : Color.white.opacity(0.08),
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
