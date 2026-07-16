import SwiftUI
import SwiftData

@main
struct GentleWakeApp: App {
    @State private var coordinator = AlarmCoordinator()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(coordinator)
                .preferredColorScheme(.dark)
                .tint(Theme.accentBright)
        }
        .modelContainer(for: [AlarmSettings.self, SleepSession.self])
    }
}
