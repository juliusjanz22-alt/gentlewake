import UIKit

enum Haptics {
    static func tick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }

    static func toggle() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
