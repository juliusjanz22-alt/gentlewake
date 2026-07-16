import SwiftUI
import SwiftData

@main
struct GentleWakeApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
                .tint(Theme.accentBright)
        }
        .modelContainer(for: AlarmSettings.self)
    }
}
