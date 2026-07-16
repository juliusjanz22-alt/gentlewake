import Foundation

/// How volume rises across the fade-in window. Raw values persist in
/// `AlarmSettings.fadeCurve`; the audio engine and the settings UI's mini
/// previews both evaluate `volume(at:)`.
enum FadeCurve: String, CaseIterable, Identifiable {
    case gentle
    case balanced
    case steep

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gentle: "Gentle"
        case .balanced: "Balanced"
        case .steep: "Steep"
        }
    }

    /// Maps elapsed fraction (0–1) to volume fraction (0–1).
    func volume(at t: Double) -> Double {
        switch self {
        case .gentle: t * t
        case .balanced: t
        case .steep: 1 - (1 - t) * (1 - t)
        }
    }
}
