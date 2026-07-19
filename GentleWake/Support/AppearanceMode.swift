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

/// Applies the stored appearance preference. Must be attached to every
/// independently-presented surface (sheets, full-screen covers) — SwiftUI
/// does NOT propagate the root's preferredColorScheme into those contexts,
/// so without this a sheet stays in its old scheme when the toggle flips.
private struct AppAppearanceModifier: ViewModifier {
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.defaultRaw

    func body(content: Content) -> some View {
        content.preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
    }
}

extension View {
    func appAppearance() -> some View {
        modifier(AppAppearanceModifier())
    }
}
