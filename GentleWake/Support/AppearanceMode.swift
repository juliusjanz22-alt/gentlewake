import SwiftUI

/// User's appearance preference, persisted in UserDefaults under
/// `appearanceMode` and applied at the app root via preferredColorScheme.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// nil follows the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    static let storageKey = "appearanceMode"
    /// Light is the redesign's delivered identity, so it's the default.
    static let defaultRaw = AppearanceMode.light.rawValue
}
