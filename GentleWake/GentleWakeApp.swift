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
                .tint(Theme.accent)
                // Light is the primary identity of the redesign. The theme
                // fully supports dark (kept for a future Auto/Dark toggle);
                // forcing light here means everyone sees the intended look.
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [AlarmSettings.self, SleepSession.self])
    }
}
