import SwiftUI
import SwiftData

/// The sound picker: random-mode toggle on top, then a two-column card grid
/// per category (matching the reference's library screen). Tap previews are
/// wired in Phase 3 when the audio engine lands.
struct SoundLibraryView: View {
    @Bindable var settings: AlarmSettings

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                randomModeCard

                ForEach(AlarmSound.Category.allCases) { category in
                    section(for: category)
                }

                importFooter
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .background(Theme.sheetBackground)
        .navigationTitle("Alarm sound")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.sheetBackground, for: .navigationBar)
    }

    // MARK: - Random mode

    private var randomModeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: $settings.randomSoundMode) {
                HStack(spacing: 10) {
                    Image(systemName: "shuffle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accentBright)
                    Text("Random mode")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .tint(Theme.accent)

            Text("No more alarm monotony — a different sound every morning.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Category sections

    private func section(for category: AlarmSound.Category) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                    .foregroundStyle(Theme.accentBright)
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("· \(category.subtitle)")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(SoundCatalog.sounds(in: category)) { sound in
                    SoundCardView(sound: sound, isSelected: settings.soundID == sound.id) {
                        settings.soundID = sound.id
                        Haptics.tick()
                    }
                }
            }
        }
    }

    // MARK: - Import footer

    private var importFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            importRow(icon: "square.and.arrow.down", title: "Import your own audio")
            importRow(icon: "music.note.list", title: "Sync from Apple Music")
        }
        .font(.subheadline)
        .padding(16)
        .background(Theme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func importRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.textSecondary)
            Text(title)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            LockBadge()
        }
        .opacity(0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). Locked, coming soon")
    }
}
