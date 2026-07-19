import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AlarmCoordinator.self) private var coordinator
    @Environment(HomeStore.self) private var homeStore
    @Query private var storedSettings: [AlarmSettings]
    @State private var activeSheet: Sheet?

    private enum Sheet: String, Identifiable {
        case profile, nextSleep, alarmOptions

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            AppBackground()

            if let settings = storedSettings.first {
                content(settings)
            }
        }
        .onAppear {
            ensureSettingsExist()
            let context = modelContext
            coordinator.attach {
                try? context.fetch(FetchDescriptor<AlarmSettings>()).first
            }
            coordinator.recordSession = { settings, wakeDate in
                let session = SleepSession(
                    date: wakeDate,
                    bedtimeMinutes: settings.bedtimeMinutes,
                    wakeMinutes: settings.wakeMinutes,
                    durationMinutes: settings.sleepDurationMinutes
                )
                context.insert(session)
                if HealthStore.shared.isConnected {
                    Task { await HealthStore.shared.contribute(session: session) }
                }
            }
            let homeStore = self.homeStore
            coordinator.sunriseUpdate = { progress in
                guard let settings = try? context.fetch(FetchDescriptor<AlarmSettings>()).first,
                      settings.sunriseEnabled else { return }
                homeStore.connect()
                let ids = Set(settings.sunriseAccessoryIDs.split(separator: ",").map(String.init))
                homeStore.applySunrise(progress: progress, accessoryIDs: ids)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { coordinator.showsSleepUI },
            set: { _ in }
        )) {
            Group {
                if let settings = storedSettings.first {
                    switch coordinator.phase {
                    case .ringing, .nudging:
                        RingingView(settings: settings)
                    case .brief:
                        MorningBriefView(settings: settings)
                    default:
                        SleepModeView(settings: settings)
                    }
                }
            }
            .appAppearance()
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .profile:
                    if let settings = storedSettings.first {
                        ProfileView(settings: settings)
                    }
                case .nextSleep:
                    if let settings = storedSettings.first {
                        NextSleepView(settings: settings)
                    }
                case .alarmOptions:
                    if let settings = storedSettings.first {
                        AlarmOptionsView(settings: settings)
                    }
                }
            }
            .appAppearance()
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

            Spacer(minLength: 12)

            alarmToggle(settings)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Top bar

    // Greeting on the left, profile on the right — the app is fully free, so
    // no trial counter.
    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: -2) {
                Text(greeting)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Rest well tonight")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            CircleGlassButton(systemImage: "person.fill", label: "Profile") {
                activeSheet = .profile
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
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
        .accessibilityLabel("Sleep duration: \(settings.sleepDurationMinutes.asSpokenDuration)")
        .accessibilityHint("Shows your next sleep details")
    }

    // MARK: - Alarm toggle

    private func alarmToggle(_ settings: AlarmSettings) -> some View {
        Button {
            settings.isEnabled.toggle()
            if settings.isEnabled {
                coordinator.armed(settings)
            } else {
                coordinator.disarmed()
            }
            Haptics.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: settings.isEnabled ? "bell.fill" : "bell.slash")
                    .font(.subheadline.weight(.semibold))
                Text(settings.isEnabled ? "Alarm on" : "Alarm off")
                    .font(.headline)
            }
            .foregroundStyle(settings.isEnabled ? Color.white : Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule().fill(
                    settings.isEnabled
                        ? AnyShapeStyle(Theme.accent)
                        : AnyShapeStyle(Theme.surface)
                )
            )
            .overlay(
                Capsule().strokeBorder(
                    settings.isEnabled ? .clear : Theme.surfaceStroke,
                    lineWidth: 1
                )
            )
            .shadow(
                color: settings.isEnabled ? Theme.accent.opacity(0.3) : Theme.cardShadow.opacity(0.05),
                radius: settings.isEnabled ? 14 : 8,
                y: settings.isEnabled ? 6 : 3
            )
        }
        .accessibilityLabel("Alarm")
        .accessibilityValue(settings.isEnabled ? "On" : "Off")
        .accessibilityHint("Double tap to turn the alarm \(settings.isEnabled ? "off" : "on")")
    }

    // MARK: - Bootstrap

    private func ensureSettingsExist() {
        let settings: AlarmSettings
        if let existing = storedSettings.first {
            settings = existing
        } else {
            settings = AlarmSettings()
            modelContext.insert(settings)
        }
        applyUITestScenario(to: settings)
    }

    /// UI tests pass `-UITestScenario <name>` to put the app into a known
    /// state: `clean` resets persisted settings so screenshots are
    /// deterministic; `sleepCycle` arms a compressed sleep window (paired
    /// with the scaled debug clock); `backupChain` exercises the tier-3
    /// notification chain on a short real-time fuse.
    private func applyUITestScenario(to settings: AlarmSettings) {
        switch UserDefaults.standard.string(forKey: "UITestScenario") {
        case "clean":
            settings.bedtimeMinutes = 23 * 60
            settings.wakeMinutes = 7 * 60
            settings.isEnabled = false
            settings.fadeInMinutes = 15
            settings.fadeCurve = FadeCurve.gentle.rawValue
            settings.startVolume = 0
            settings.endVolume = 0.8
            settings.nudgeEnabled = true
            settings.soundID = "cabin-day"
            settings.randomSoundMode = false
            // Reset appearance to light so the dark-toggle test doesn't leave
            // later tests rendering dark (UserDefaults persists across launches).
            UserDefaults.standard.set(AppearanceMode.light.rawValue, forKey: AppearanceMode.storageKey)
            // Wipe recorded nights so trend/consistency screenshots are
            // deterministic regardless of which live tests ran before.
            try? modelContext.delete(model: SleepSession.self)
        case "sleepCycle":
            settings.bedtimeMinutes = 23 * 60
            settings.wakeMinutes = 23 * 60 + 20
            settings.fadeInMinutes = 10
            settings.isEnabled = true
            settings.startVolume = 0
            settings.endVolume = 0.8
            settings.nudgeEnabled = true
        case "backupChain":
            settings.isEnabled = false
            Task {
                _ = await NotificationBackup.requestAuthorization()
                await NotificationBackup.schedule(
                    wakeMinutes: settings.wakeMinutes,
                    debugLeadSeconds: 12
                )
            }
        case "healthSeed":
            settings.isEnabled = false
            Task {
                await HealthStore.shared.requestAuthorization()
                await HealthStore.shared.seedSampleNights()
            }
        default:
            break
        }
    }
}
