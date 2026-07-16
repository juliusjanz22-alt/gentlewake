import SwiftUI
import SwiftData

/// Profile sheet: entry points to alarm settings, sound, sleep tracking and
/// the morning brief, plus FAQ. The reference shows a subscription banner up
/// top — omitted deliberately: this rebuild is completely free.
struct ProfileView: View {
    @Bindable var settings: AlarmSettings
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Destination] = []

    enum Destination: Hashable {
        case alarmSettings
        case sounds
        case nextSleep
        case morningBrief
        case faq
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {
                        row(
                            icon: "alarm.fill",
                            title: "Alarm Settings",
                            subtitle: "Manage your alarm sound, volume, and fade-in options",
                            destination: .alarmSettings
                        )
                        soundRow
                        row(
                            icon: "sparkles",
                            title: "Sleep gate & tracking",
                            subtitle: "Your sleep window, consistency, and duration trend",
                            destination: .nextSleep
                        )
                        row(
                            icon: "sun.horizon.fill",
                            title: "Morning brief",
                            subtitle: "Choose what appears when you wake: calendar, weather, reminders",
                            destination: .morningBrief
                        )
                        row(
                            icon: "questionmark.circle.fill",
                            title: "FAQ & Feedback",
                            subtitle: "How the gentle wake-up works, and how to reach us",
                            destination: .faq
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 90)
                }

                closeButton
            }
            .background(Theme.sheetBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.sheetBackground, for: .navigationBar)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .alarmSettings:
                    AlarmOptionsContent(settings: settings)
                case .sounds:
                    SoundLibraryView(settings: settings)
                case .nextSleep:
                    NextSleepView(settings: settings)
                case .morningBrief:
                    MorningBriefSettingsView(settings: settings)
                case .faq:
                    FAQView()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Rows

    private func row(icon: String, title: String, subtitle: String, destination: Destination) -> some View {
        Button {
            path.append(destination)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Theme.accentBright)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private var soundRow: some View {
        Button {
            path.append(.sounds)
        } label: {
            HStack(spacing: 14) {
                Group {
                    if let sound = SoundCatalog.sound(for: settings.soundID) {
                        SoundArtworkView(sound: sound)
                    } else {
                        Theme.surface
                    }
                }
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Alarm sound")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    Text(currentSoundName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Alarm sound: \(currentSoundName)")
        .accessibilityHint("Opens the sound library")
    }

    private var currentSoundName: String {
        if settings.randomSoundMode {
            return "Random every day"
        }
        return SoundCatalog.sound(for: settings.soundID)?.name ?? "Not set"
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Close")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 44)
                .padding(.vertical, 15)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.surfaceStroke, lineWidth: 1))
        }
        .padding(.bottom, 12)
        .accessibilityLabel("Close profile")
    }
}
