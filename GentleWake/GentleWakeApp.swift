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
                // Sheets/covers each re-apply this too (see appAppearance);
                // SwiftUI doesn't propagate it into those contexts.
                .appAppearance()
        }
        .modelContainer(for: [AlarmSettings.self, SleepSession.self])
    }
}
