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

                Text("Live calendar, weather and reminders data connects in the integrations phase.")
                    .font(.caption2)
                    .foregroundStyle(Theme.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .background(Theme.sheetBackground)
        .navigationTitle("Morning brief")
        .navigationBarTitleDisplayMode(.inline)
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
