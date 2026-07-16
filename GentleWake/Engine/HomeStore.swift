import Foundation
import HomeKit
import Observation

/// HomeKit bridge for the smart-light sunrise. Instantiated lazily —
/// creating HMHomeManager triggers the system permission prompt, so nothing
/// touches HomeKit until the user opens the sunrise settings or an armed
/// sunrise fade actually needs the lights.
@Observable
final class HomeStore: NSObject, HMHomeManagerDelegate {
    private var manager: HMHomeManager?
    private(set) var lights: [HMAccessory] = []
    private(set) var isLoading = false
    private var lastAppliedStep = -1

    func connect() {
        guard manager == nil else { return }
        isLoading = true
        let manager = HMHomeManager()
        manager.delegate = self
        self.manager = manager
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        isLoading = false
        lights = manager.homes.flatMap(\.accessories).filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLightbulb }
        }
    }

    /// Ramps the selected bulbs with the fade: power on, brightness follows
    /// progress. Throttled to 5% steps to avoid flooding the accessories.
    func applySunrise(progress: Double, accessoryIDs: Set<String>) {
        let step = Int(progress * 20)
        guard step != lastAppliedStep else { return }
        lastAppliedStep = step

        for accessory in lights where accessoryIDs.contains(accessory.uniqueIdentifier.uuidString) {
            for service in accessory.services where service.serviceType == HMServiceTypeLightbulb {
                for characteristic in service.characteristics {
                    switch characteristic.characteristicType {
                    case HMCharacteristicTypePowerState:
                        characteristic.writeValue(true) { _ in }
                    case HMCharacteristicTypeBrightness:
                        characteristic.writeValue(max(1, Int(progress * 100))) { _ in }
                    default:
                        break
                    }
                }
            }
        }
    }

    func resetSunrise() {
        lastAppliedStep = -1
    }
}
