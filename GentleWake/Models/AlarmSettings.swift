import Foundation
import SwiftData

/// The single alarm configuration. The app is a one-alarm product: the home
/// dial edits this instance in place. Fade/sound fields are consumed from
/// Phase 2 onward but live here so the schema doesn't churn.
@Model
final class AlarmSettings {
    var bedtimeMinutes: Int
    var wakeMinutes: Int
    var isEnabled: Bool

    // Fade-in (Phase 2+)
    var fadeInMinutes: Int
    var fadeCurve: String
    var startVolume: Double
    var endVolume: Double
    var nudgeEnabled: Bool

    // Sound selection (Phase 2+)
    var soundID: String
    var randomSoundMode: Bool

    init(
        bedtimeMinutes: Int = 23 * 60,
        wakeMinutes: Int = 7 * 60,
        isEnabled: Bool = false,
        fadeInMinutes: Int = 15,
        fadeCurve: String = FadeCurve.gentle.rawValue,
        startVolume: Double = 0.0,
        endVolume: Double = 0.8,
        nudgeEnabled: Bool = true,
        soundID: String = "cabin-day",
        randomSoundMode: Bool = false
    ) {
        self.bedtimeMinutes = bedtimeMinutes
        self.wakeMinutes = wakeMinutes
        self.isEnabled = isEnabled
        self.fadeInMinutes = fadeInMinutes
        self.fadeCurve = fadeCurve
        self.startVolume = startVolume
        self.endVolume = endVolume
        self.nudgeEnabled = nudgeEnabled
        self.soundID = soundID
        self.randomSoundMode = randomSoundMode
    }

    /// Sleep window length; handles overnight wrap (e.g. 23:00 → 07:00 = 8h).
    var sleepDurationMinutes: Int {
        (wakeMinutes - bedtimeMinutes + 1440) % 1440
    }
}
