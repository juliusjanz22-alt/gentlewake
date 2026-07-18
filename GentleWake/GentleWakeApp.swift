import SwiftUI
import SwiftData

@main
struct GentleWakeApp: App {
    @State private var coordinator = AlarmCoordinator()
    @State private var homeStore = HomeStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(coordinator)
                .environment(homeStore)
                .tint(Theme.accentBright)
        }
        .modelContainer(for: [AlarmSettings.self, SleepSession.self])
    }
}
