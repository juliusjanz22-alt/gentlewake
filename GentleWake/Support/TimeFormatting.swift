import Foundation

/// Times throughout the app are stored as minutes from midnight (0..<1440),
/// which makes dial math and overnight-window arithmetic trivial.
extension Int {
    /// Locale-aware clock string, e.g. "07:30" or "7:30 AM".
    var asClockTime: String {
        var components = DateComponents()
        components.hour = self / 60
        components.minute = self % 60
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Duration string matching the reference, e.g. "8h 0m".
    var asDuration: String {
        "\(self / 60)h \(self % 60)m"
    }

    /// Spoken form for VoiceOver, e.g. "8 hours 0 minutes".
    var asSpokenDuration: String {
        "\(self / 60) hours \(self % 60) minutes"
    }

    var wrappedToDay: Int {
        ((self % 1440) + 1440) % 1440
    }
}
