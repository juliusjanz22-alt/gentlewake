import SwiftUI

/// Shown right after dismissing the alarm: a calm hand-off into the day with
/// the panels chosen in settings. Layout is INFERRED — the reference names
/// the feature and its three data sources but never shows the screen. Panel
/// data is placeholder until the integrations phase wires EventKit/WeatherKit.
struct MorningBriefView: View {
    @Environment(AlarmCoordinator.self) private var coordinator
    let settings: AlarmSettings

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                sun

                Text("Good morning!")
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 24)

                Text(coordinator.clock.now.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    if settings.briefWeather {
                        panel(
                            icon: "cloud.sun.fill",
                            title: "Weather",
                            detail: "Connects in the integrations phase"
                        )
                    }
                    if settings.briefCalendar {
                        panel(
                            icon: "calendar",
                            title: "Today's events",
                            detail: "Connects in the integrations phase"
                        )
                    }
                    if settings.briefReminders {
                        panel(
                            icon: "checklist",
                            title: "Reminders",
                            detail: "Connects in the integrations phase"
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)

                Spacer()

                Button {
                    coordinator.finishBrief()
                    Haptics.toggle()
                } label: {
                    Text("Start the day")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 54)
                        .padding(.vertical, 17)
                        .background(Theme.accent, in: Capsule())
                        .shadow(color: Theme.accent.opacity(0.35), radius: 16, y: 6)
                }
                .padding(.bottom, 40)
                .accessibilityHint("Closes the morning brief")
            }
        }
    }

    private var sun: some View {
        ZStack {
            Circle()
                .fill(Theme.accentSoft)
                .frame(width: 132, height: 132)
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
        }
        .accessibilityHidden(true)
    }

    private func panel(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.accentBright)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
