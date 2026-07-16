import Foundation

/// Source of "now" for the alarm engine. Production uses the real clock;
/// tests inject a scaled clock so a full sleep→fade→ring cycle plays out in
/// seconds. This is the seam that makes the live alarm behavior verifiable
/// in CI rather than reviewed as static UI.
protocol AppClock {
    var now: Date { get }
    /// Scale factor: 1 in production; N compresses N seconds of app time
    /// into 1 real second (used to shorten timer intervals in debug).
    var scale: Double { get }
}

struct RealClock: AppClock {
    var now: Date { .now }
    let scale = 1.0
}

/// Runs app time from `start`, advancing `scale`× faster than real time.
struct ScaledClock: AppClock {
    let start: Date
    let anchor: Date
    let scale: Double

    var now: Date {
        start.addingTimeInterval(Date.now.timeIntervalSince(anchor) * scale)
    }
}

enum ClockFactory {
    /// Reads `-DebugClockStartMinutes <minutes-from-midnight>` and
    /// `-DebugClockScale <factor>` launch arguments (surfaced via
    /// UserDefaults). Returns the real clock when absent.
    static func make() -> AppClock {
        let defaults = UserDefaults.standard
        let scale = defaults.double(forKey: "DebugClockScale")
        guard scale > 0 else { return RealClock() }

        let startMinutes = defaults.integer(forKey: "DebugClockStartMinutes")
        let midnight = Calendar.current.startOfDay(for: .now)
        let start = midnight.addingTimeInterval(Double(startMinutes) * 60)
        return ScaledClock(start: start, anchor: .now, scale: scale)
    }
}

extension Date {
    /// Fractional minutes from midnight for this date (0..<1440).
    var minutesOfDay: Double {
        let start = Calendar.current.startOfDay(for: self)
        return timeIntervalSince(start) / 60
    }
}
