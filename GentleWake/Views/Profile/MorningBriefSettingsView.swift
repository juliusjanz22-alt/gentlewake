import SwiftUI
import SwiftData

/// Which panels appear on the morning brief after waking. The reference
/// profile row names calendar, weather and reminders; the toggles-in-cards
/// layout is INFERRED from the source's design language.
struct MorningBriefSettingsView: View {
    @Bindable var settings: AlarmSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Choose what appears on your morning brief right after you wake up.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                lockedDataBanner

                toggleCard(
                    icon: "calendar",
                    title: "Calendar",
                    subtitle: "Your first events of the day",
                    isOn: $settings.briefCalendar
                )
                toggleCard(
                    icon: "cloud.sun.fill",
                    title: "Weather",
                    subtitle: "Conditions for the morning ahead",
                    isOn: $settings.briefWeather
                )
                toggleCard(
                    icon: "checklist",
                    title: "Reminders",
                    subtitle: "Tasks due today",
                    isOn: $settings.briefReminders
                )

            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .background(Theme.sheetBackground)
        .navigationTitle("Morning brief")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// You can pick panels now, but the live data behind them isn't built —
    /// call that out clearly rather than letting it look finished.
    private var lockedDataBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            Text("Live weather, calendar and reminders data is coming soon. You can choose the panels now.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.track.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func toggleCard(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
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
                }
            }
        }
        .tint(Theme.accent)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
    }
}
