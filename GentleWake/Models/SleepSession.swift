import Foundation
import SwiftData

/// One recorded night. The engine logs a session when the user dismisses the
/// alarm, so tracking works fully offline from day one; HealthKit/motion
/// samples (Phase 6) enrich rather than replace this.
@Model
final class SleepSession {
    /// The wake-up date (used as the day key).
    var date: Date
    var bedtimeMinutes: Int
    var wakeMinutes: Int
    var durationMinutes: Int

    init(date: Date, bedtimeMinutes: Int, wakeMinutes: Int, durationMinutes: Int) {
        self.date = date
        self.bedtimeMinutes = bedtimeMinutes
        self.wakeMinutes = wakeMinutes
        self.durationMinutes = durationMinutes
    }
}

/// Night quality grade, as shown in the reference's consistency badges.
/// Thresholds are INFERRED (duration vs. the common 7.5–8h guidance); the
/// source app's exact grading inputs aren't documented.
enum SleepGrade: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case poor = "Poor"
    case critical = "Critical"

    static func forDuration(minutes: Int) -> SleepGrade {
        switch minutes {
        case (7 * 60 + 30)...: .excellent
        case (6 * 60 + 30)...: .good
        case (5 * 60 + 30)...: .poor
        default: .critical
        }
    }

    var symbol: String {
        switch self {
        case .excellent: "sparkles"
        case .good: "checkmark.seal.fill"
        case .poor: "exclamationmark.circle.fill"
        case .critical: "exclamationmark.triangle.fill"
        }
    }
}
