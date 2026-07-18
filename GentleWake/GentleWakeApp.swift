import SwiftUI
import SwiftData

@main
struct GentleWakeApp: App {
    @State private var coordinator = AlarmCoordinator()
    @State private var homeStore = HomeStore()
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.defaultRaw

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(coordinator)
                .environment(homeStore)
                .tint(Theme.accent)
                // Driven by the Appearance setting in Profile; light default.
                .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
        }
        .modelContainer(for: [AlarmSettings.self, SleepSession.self])
    }
}
