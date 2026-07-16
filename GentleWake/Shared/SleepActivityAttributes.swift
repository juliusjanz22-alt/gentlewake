import ActivityKit
import Foundation

/// Live Activity payload shared between the app (which starts/updates the
/// activity) and the widget extension (which renders it on the lock screen
/// and in the Dynamic Island).
struct SleepActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Mirrors AlarmCoordinator.Phase (string to stay Codable-stable).
        var phaseName: String
        /// Fade progress 0–1 (meaningful during the fading phase).
        var progress: Double
        /// Display string for the wake time, e.g. "07:00".
        var wakeTimeText: String

        var isRinging: Bool {
            phaseName == "ringing" || phaseName == "nudging"
        }

        var isFading: Bool {
            phaseName == "fading"
        }
    }

    /// Display string for bedtime, fixed for the activity's lifetime.
    var bedtimeText: String
}
