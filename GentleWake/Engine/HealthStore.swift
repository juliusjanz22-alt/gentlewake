import Foundation
import HealthKit

/// Sleep-analysis bridge to Apple Health. Read access enriches the trend and
/// nights-analyzed counters; write access exists so recorded sessions can be
/// contributed back (and so CI can seed sample nights and verify a real
/// round trip through the Health store).
final class HealthStore {
    static let shared = HealthStore()

    private let store = HKHealthStore()
    private let sleepType = HKCategoryType(.sleepAnalysis)

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var isConnected: Bool {
        UserDefaults.standard.bool(forKey: "healthConnected")
    }

    /// Requests read+share for sleep analysis. Returns whether the request
    /// completed (HealthKit hides per-type read grants by design).
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [sleepType], read: [sleepType])
            UserDefaults.standard.set(true, forKey: "healthConnected")
            return true
        } catch {
            return false
        }
    }

    /// Sleep minutes per night over the trailing week, newest first.
    func recentNights(days: Int = 7) async -> [(date: Date, minutes: Int)] {
        guard isAvailable else { return [] }
        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        let asleepValues = Set(HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue))
        var byDay: [Date: Int] = [:]
        let calendar = Calendar.current
        for sample in samples where asleepValues.contains(sample.value) {
            let day = calendar.startOfDay(for: sample.endDate)
            let minutes = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
            byDay[day, default: 0] += minutes
        }
        return byDay.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }

    /// Writes a recorded night back to Health (best-effort; no-op when
    /// share authorization was denied).
    func contribute(session: SleepSession) async {
        guard isAvailable else { return }
        let end = session.date
        let start = end.addingTimeInterval(-Double(session.durationMinutes) * 60)
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: start,
            end: end
        )
        try? await store.save(sample)
    }

    /// CI seeding: writes `count` synthetic nights so the read path can be
    /// verified against a populated store in the simulator.
    func seedSampleNights(count: Int = 5) async {
        guard isAvailable else { return }
        let calendar = Calendar.current
        let durations = [462, 431, 488, 401, 475] // minutes, deterministic
        for index in 0..<count {
            guard let wake = calendar.date(byAdding: .day, value: -(index + 1), to: .now) else { continue }
            let minutes = durations[index % durations.count]
            let sample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                start: wake.addingTimeInterval(-Double(minutes) * 60),
                end: wake
            )
            try? await store.save(sample)
        }
    }
}
