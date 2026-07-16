import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var storedSettings: [AlarmSettings]
    @State private var trial = TrialManager()
    @State private var activeSheet: Sheet?

    private enum Sheet: String, Identifiable {
        case profile, nextSleep, alarmOptions

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            StarfieldBackground()

            if let settings = storedSettings.first {
                content(settings)
            }
        }
        .onAppear(perform: ensureSettingsExist)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .profile:
                PlaceholderSheet(title: "Profile", phase: "Phase 5")
            case .nextSleep:
                PlaceholderSheet(title: "Your next sleep", phase: "Phase 4")
            case .alarmOptions:
                PlaceholderSheet(title: "Alarm settings", phase: "Phase 2")
            }
        }
    }

    private func content(_ settings: AlarmSettings) -> some View {
        VStack(spacing: 0) {
            topBar
            sleepDurationPill(settings)
                .padding(.top, 20)

            Spacer(minLength: 12)

            SleepDialView(settings: settings) {
                activeSheet = .alarmOptions
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 12)

            alarmToggle(settings)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "clock.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.accentBright)
                Text("\(trial.daysLeft) days left")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
            }
            .glassPill(horizontalPadding: 14, verticalPadding: 9)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Free trial: \(trial.daysLeft) days left")

            Spacer()

            CircleGlassButton(systemImage: "person.fill", label: "Profile") {
                activeSheet = .profile
            }
        }
    }

    // MARK: - Sleep duration

    private func sleepDurationPill(_ settings: AlarmSettings) -> some View {
        Button {
            activeSheet = .nextSleep
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "moon.stars.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.accentBright)
                Text("Sleep duration: ")
                    .foregroundStyle(Theme.textPrimary)
                + Text(settings.sleepDurationMinutes.asDuration)
                    .bold()
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .font(.subheadline)
            .glassPill()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sleep duration: \(settings.sleepDurationMinutes.asSpokenDuration)")
        .accessibilityHint("Shows your next sleep details")
    }

    // MARK: - Alarm toggle

    private func alarmToggle(_ settings: AlarmSettings) -> some View {
        Button {
            settings.isEnabled.toggle()
            Haptics.toggle()
        } label: {
            HStack(spacing: 8) {
                Text(settings.isEnabled ? "Alarm on" : "Alarm off")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 38)
            .padding(.vertical, 17)
            .background(
                Capsule().fill(
                    settings.isEnabled
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Theme.accentDeep, Theme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        : AnyShapeStyle(Color.white.opacity(0.04))
                )
            )
            .overlay(
                Capsule().strokeBorder(
                    LinearGradient(
                        colors: [Theme.accentBright.opacity(0.7), Theme.surfaceStroke],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: settings.isEnabled ? Theme.accent.opacity(0.5) : .clear, radius: 16)
        }
        .accessibilityLabel("Alarm")
        .accessibilityValue(settings.isEnabled ? "On" : "Off")
        .accessibilityHint("Double tap to turn the alarm \(settings.isEnabled ? "off" : "on")")
    }

    // MARK: - Bootstrap

    private func ensureSettingsExist() {
        guard storedSettings.isEmpty else { return }
        modelContext.insert(AlarmSettings())
    }
}
