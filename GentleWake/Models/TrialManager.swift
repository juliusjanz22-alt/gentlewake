import Foundation
import Observation

/// Tracks the 7-day free trial window from first launch.
/// Phase 6 extends this with StoreKit entitlements; until then the app
/// only displays the counter and never gates features.
@Observable
final class TrialManager {
    static let trialDays = 7
    private static let firstLaunchKey = "firstLaunchDate"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Self.firstLaunchKey) == nil {
            defaults.set(Date.now, forKey: Self.firstLaunchKey)
        }
    }

    var daysLeft: Int {
        guard let start = defaults.object(forKey: Self.firstLaunchKey) as? Date else {
            return Self.trialDays
        }
        let elapsed = Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0
        return max(0, Self.trialDays - elapsed)
    }

    var isExpired: Bool {
        daysLeft <= 0
    }
}
