import Foundation

#if LITE

/// LITE build (free-provisioning sideload): Live Activities need the widget
/// extension + entitlement, which a free Apple ID can't sign. Stub keeps the
/// coordinator's call sites unchanged while doing nothing.
final class LiveActivityController {
    func begin(bedtimeText: String, wakeTimeText: String) {}
    func update(phaseName: String, progress: Double, wakeTimeText: String) {}
    func end() {}
}

#else

import ActivityKit

/// Starts/updates/ends the sleep Live Activity alongside the coordinator's
/// phase transitions. Fade progress updates are throttled — ActivityKit
/// rate-limits updates, and the lock screen doesn't need 2Hz precision.
final class LiveActivityController {
    private var activity: Activity<SleepActivityAttributes>?
    private var lastSentProgress: Double = -1

    func begin(bedtimeText: String, wakeTimeText: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        let attributes = SleepActivityAttributes(bedtimeText: bedtimeText)
        let state = SleepActivityAttributes.ContentState(
            phaseName: "sleeping",
            progress: 0,
            wakeTimeText: wakeTimeText
        )
        activity = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil)
        )
    }

    func update(phaseName: String, progress: Double, wakeTimeText: String) {
        guard let activity else { return }
        // Skip sub-5% progress deltas unless the phase itself changed.
        let phaseChanged = activity.content.state.phaseName != phaseName
        if !phaseChanged && abs(progress - lastSentProgress) < 0.05 { return }
        lastSentProgress = progress

        let state = SleepActivityAttributes.ContentState(
            phaseName: phaseName,
            progress: progress,
            wakeTimeText: wakeTimeText
        )
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        lastSentProgress = -1
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

#endif
