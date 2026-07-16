import SwiftUI

/// One entry in the alarm-sound catalog. Audio is synthesized at runtime as a
/// placeholder (Phase 3); artwork is generated from a stable per-sound hue —
/// both swap for real assets at final branding.
struct AlarmSound: Identifiable, Equatable {
    enum Category: String, CaseIterable, Identifiable {
        case nature
        case melody
        case nudge

        var id: String { rawValue }

        var title: String {
            switch self {
            case .nature: "Nature"
            case .melody: "Melodies"
            case .nudge: "Special & Nudge"
            }
        }

        var subtitle: String {
            switch self {
            case .nature: "Mastered soundscapes"
            case .melody: "Orchestrated tracks"
            case .nudge: "High-certainty sounds"
            }
        }

        var icon: String {
            switch self {
            case .nature: "leaf.fill"
            case .melody: "music.note"
            case .nudge: "bell.fill"
            }
        }
    }

    let id: String
    let name: String
    let category: Category
    let symbol: String

    /// Stable hue in [0, 1) derived from the id (not `hashValue`, which changes
    /// between launches and would reshuffle artwork in every screenshot run).
    var artHue: Double {
        var hash: UInt64 = 5381
        for scalar in id.unicodeScalars {
            hash = (hash &* 33) &+ UInt64(scalar.value)
        }
        return Double(hash % 360) / 360
    }
}

enum SoundCatalog {
    static let all: [AlarmSound] = nature + melodies + nudges

    static func sound(for id: String) -> AlarmSound? {
        all.first { $0.id == id }
    }

    static func sounds(in category: AlarmSound.Category) -> [AlarmSound] {
        all.filter { $0.category == category }
    }

    // Names follow the PDF's catalog listing (37 sounds).

    static let nature: [AlarmSound] = [
        .init(id: "jungle-birdsong", name: "Jungle Birdsong", category: .nature, symbol: "bird.fill"),
        .init(id: "morning-birds", name: "Morning Birds", category: .nature, symbol: "bird"),
        .init(id: "zen-garden", name: "Zen Garden", category: .nature, symbol: "tree.fill"),
        .init(id: "forest-chorus", name: "Forest Chorus", category: .nature, symbol: "tree"),
        .init(id: "alps", name: "Alps", category: .nature, symbol: "mountain.2.fill"),
        .init(id: "coast", name: "Coast", category: .nature, symbol: "water.waves"),
        .init(id: "oceanic-sounds", name: "Oceanic Sounds", category: .nature, symbol: "fish.fill"),
        .init(id: "misty-wetlands", name: "Misty Wetlands", category: .nature, symbol: "cloud.fog.fill"),
        .init(id: "wind", name: "Wind", category: .nature, symbol: "wind"),
        .init(id: "river", name: "River", category: .nature, symbol: "drop.fill"),
    ]

    static let melodies: [AlarmSound] = [
        .init(id: "sylvan-harp", name: "Sylvan Harp", category: .melody, symbol: "music.quarternote.3"),
        .init(id: "ancient-temple", name: "Ancient Temple", category: .melody, symbol: "building.columns.fill"),
        .init(id: "lumen", name: "Lumen", category: .melody, symbol: "rays"),
        .init(id: "city-view", name: "City View", category: .melody, symbol: "building.2.fill"),
        .init(id: "evening-shore", name: "Evening Shore", category: .melody, symbol: "sunset.fill"),
        .init(id: "amethis", name: "Amethis", category: .melody, symbol: "diamond.fill"),
        .init(id: "caelus", name: "Caelus (Airy Piano)", category: .melody, symbol: "pianokeys"),
        .init(id: "pyramid-whisper", name: "Pyramid Whisper", category: .melody, symbol: "triangle.fill"),
        .init(id: "meadow", name: "Meadow", category: .melody, symbol: "camera.macro"),
        .init(id: "aeral-shore", name: "Aeral Shore", category: .melody, symbol: "beach.umbrella.fill"),
        .init(id: "veil", name: "Veil", category: .melody, symbol: "moon.haze.fill"),
        .init(id: "fireside", name: "Fireside", category: .melody, symbol: "flame.fill"),
        .init(id: "daychorus", name: "Daychorus", category: .melody, symbol: "sun.max.fill"),
        .init(id: "cabin-day", name: "Cabin Day", category: .melody, symbol: "house.fill"),
    ]

    static let nudges: [AlarmSound] = [
        .init(id: "shire", name: "Shire", category: .nudge, symbol: "leaf.circle.fill"),
        .init(id: "zanari", name: "Zanari", category: .nudge, symbol: "sparkles"),
        .init(id: "echo-of-sea", name: "Echo of Sea", category: .nudge, symbol: "water.waves.and.arrow.up"),
        .init(id: "cozy-jazz", name: "Cozy Jazz", category: .nudge, symbol: "music.mic"),
        .init(id: "evening-lounge", name: "Evening Lounge", category: .nudge, symbol: "sofa.fill"),
        .init(id: "music-box", name: "Music Box", category: .nudge, symbol: "gift.fill"),
        .init(id: "sunrise-express", name: "Sunrise Express", category: .nudge, symbol: "tram.fill"),
        .init(id: "rain", name: "Rain", category: .nudge, symbol: "cloud.rain.fill"),
        .init(id: "classic-nudge", name: "Classic Nudge", category: .nudge, symbol: "bell.badge.fill"),
        .init(id: "signal", name: "Signal", category: .nudge, symbol: "antenna.radiowaves.left.and.right"),
        .init(id: "morning-ping", name: "Morning Ping", category: .nudge, symbol: "dot.radiowaves.up.forward"),
        .init(id: "rhythm", name: "Rhythm", category: .nudge, symbol: "metronome.fill"),
        .init(id: "piano-rise", name: "Piano Rise", category: .nudge, symbol: "pianokeys.inverse"),
    ]
}
