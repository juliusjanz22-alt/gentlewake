import Foundation
import UserNotifications

/// Tier 3 of the fail-safe: a chain of local notifications straddling the
/// wake time, so the user still gets woken (system banner + sound) even if
/// iOS terminated the app overnight and the audio fade never ran.
enum NotificationBackup {
    private static let identifierPrefix = "wake-backup-"
    /// Minutes after wake time for each notification in the chain.
    private static let chainOffsets = [0, 1, 2, 4, 6]

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Schedules the chain for the next occurrence of `wakeMinutes`.
    /// `debugLeadSeconds` (from the backupChain UI-test scenario) instead
    /// anchors the chain N seconds from now so CI can observe delivery.
    static func schedule(wakeMinutes: Int, debugLeadSeconds: Int? = nil) async {
        await cancel()
        let center = UNUserNotificationCenter.current()

        let anchor: Date
        if let lead = debugLeadSeconds {
            anchor = Date.now.addingTimeInterval(Double(lead))
        } else {
            var components = DateComponents()
            components.hour = wakeMinutes / 60
            components.minute = wakeMinutes % 60
            guard let next = Calendar.current.nextDate(
                after: .now,
                matching: components,
                matchingPolicy: .nextTime
            ) else { return }
            anchor = next
        }

        for (index, offset) in chainOffsets.enumerated() {
            // Real chain: minute offsets around wake. Debug chain: 20s apart.
            let fireDate = debugLeadSeconds == nil
                ? anchor.addingTimeInterval(Double(offset * 60))
                : anchor.addingTimeInterval(Double(index * 20))
            let content = UNMutableNotificationContent()
            content.title = "Time to rise!"
            content.body = "Your gentle wake-up is going off. Open the app to stop it."
            content.sound = .default
            content.interruptionLevel = .timeSensitive

            let interval = max(1, fireDate.timeIntervalSinceNow)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(index)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    static func cancel() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeAllDeliveredNotifications()
    }

    /// Count of pending backup notifications (surfaced in the debug overlay
    /// so tests can assert the chain is actually scheduled).
    static func pendingCount() async -> Int {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix(identifierPrefix) }.count
    }
}
