import Charts
import SwiftUI
import SwiftData

/// "Your next sleep" sheet: sleep gate recommendation, planned sleep +
/// optimal alarm cards, tracking status, and the 7-night trend chart.
///
/// The sleep-gate value is a local 90-minute-cycle heuristic (INFERRED —
/// the source app derives it from Health/motion analysis, which lands in
/// the integrations phase; the reference explicitly shows a "Sample data"
/// state before data is connected, which this matches).
struct NextSleepView: View {
    @Bindable var settings: AlarmSettings
    @Query(sort: \SleepSession.date, order: .reverse) private var sessions: [SleepSession]
    @Environment(\.dismiss) private var dismiss
    @State private var showsHealthNote = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Your next sleep")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    discoverCard
                    sleepGateCard
                    HStack(spacing: 14) {
                        plannedSleepCard
                        optimalAlarmCard
                    }
                    trackingHeader
                    if let streak = consistencyStreak {
                        consistencyPill(streak)
                    }
                    connectDataCard
                    trendCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 90)
            }

            closeButton
        }
        .background(Theme.sheetBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: - Derived values

    /// Bedtime recommendation aligned to 90-minute sleep cycles before wake.
    private var sleepGateMinutes: Int {
        let cycles = max(1, Int((Double(settings.sleepDurationMinutes) / 90).rounded()))
        return (settings.wakeMinutes - cycles * 90).wrappedToDay
    }

    private var gateWindowStart: Int { (sleepGateMinutes - 45).wrappedToDay }
    private var gateWindowEnd: Int { (sleepGateMinutes + 75).wrappedToDay }

    /// Consecutive days with a recorded session, ending at the latest one.
    private var consistencyStreak: Int? {
        guard !sessions.isEmpty else { return nil }
        let calendar = Calendar.current
        let days = sessions.map { calendar.startOfDay(for: $0.date) }
        var streak = 1
        var current = days[0]
        for day in days.dropFirst() {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            if day == previous {
                streak += 1
                current = day
            } else if day != current {
                break
            }
        }
        return streak
    }

    // MARK: - Cards

    private var discoverCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accentBright)
                Text("Discover your sleep gate")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("Enable Apple Health and motion data to discover when your body is naturally primed for sleep every night.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            enableDataButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
    }

    private var sleepGateCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.accentBright)
                Text("Sleep gate")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(sleepGateMinutes.asClockTime)
                .font(.system(size: 40, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)

            Text("Is your ideal bedtime tonight to fall asleep faster and stay asleep longer.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            HStack {
                Text(gateWindowStart.asClockTime)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Theme.accentDeep, Theme.accentBright, Theme.accentDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 4)
                Text(gateWindowEnd.asClockTime)
            }
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(Theme.textSecondary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var plannedSleepCard: some View {
        let grade = SleepGrade.forDuration(minutes: settings.sleepDurationMinutes)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accentBright)
                Text("Planned sleep")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(plannedSleepText)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
            gradeBadge(grade)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var plannedSleepText: String {
        let minutes = settings.sleepDurationMinutes
        return String(format: "%02dh %02dm", minutes / 60, minutes % 60)
    }

    private var optimalAlarmCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundStyle(Theme.accentBright)
                Text("Optimal alarm")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(settings.wakeMinutes.asClockTime)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
            Text("Considering your bedtime at \(settings.bedtimeMinutes.asClockTime)")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var trackingHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.footnote)
            Text("Sleep tracking")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Theme.textPrimary)
        .glassPill()
        .padding(.top, 6)
        .accessibilityAddTraits(.isHeader)
    }

    private func consistencyPill(_ streak: Int) -> some View {
        let latestGrade = sessions.first.map { SleepGrade.forDuration(minutes: $0.durationMinutes) }
        return HStack(spacing: 10) {
            Text("Sleep consistency: Day \(streak)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
            if let grade = latestGrade {
                gradeBadge(grade)
            }
        }
        .glassPill()
        .accessibilityElement(children: .combine)
    }

    private var connectDataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Connect your data")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(min(sessions.count, 5))/5 nights analyzed")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
                    .glassPill(horizontalPadding: 10, verticalPadding: 5)
            }
            Text("Enable Motion data to see your recent sleep trend here. Apple Health can make it even richer with wearable sleep samples.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            enableDataButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last 7 nights")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Sleep duration trend")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Chart(trendData, id: \.label) { night in
                BarMark(
                    x: .value("Night", night.label),
                    y: .value("Hours", night.hours)
                )
                .cornerRadius(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accentDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYAxis {
                AxisMarks(values: [0, 4, 8]) {
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(height: 150)
            .padding(.top, 10)
            .overlay {
                if sessions.isEmpty {
                    Text("Sample data")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5), in: Capsule())
                }
            }
            .accessibilityLabel(
                sessions.isEmpty
                    ? "Sleep duration trend chart showing sample data"
                    : "Sleep duration trend chart for your last \(min(sessions.count, 7)) nights"
            )
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
    }

    private var trendData: [(label: String, hours: Double)] {
        if sessions.isEmpty {
            // Deterministic sample, mirroring the reference's pre-data state.
            let sample = [6.8, 7.5, 8.0, 7.2, 6.5, 7.9, 8.1]
            return sample.enumerated().map { ("N\($0.offset + 1)", $0.element) }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return sessions.prefix(7).reversed().map {
            (formatter.string(from: $0.date), Double($0.durationMinutes) / 60)
        }
    }

    // MARK: - Shared bits

    private func gradeBadge(_ grade: SleepGrade) -> some View {
        HStack(spacing: 4) {
            Image(systemName: grade.symbol)
                .font(.caption2)
            Text(grade.rawValue)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(gradeColor(grade))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(gradeColor(grade).opacity(0.15), in: Capsule())
    }

    private func gradeColor(_ grade: SleepGrade) -> Color {
        switch grade {
        case .excellent: Theme.accentBright
        case .good: Theme.success
        case .poor: Theme.warning
        case .critical: Color(hex: 0xF06060)
        }
    }

    private var enableDataButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                showsHealthNote = true
            } label: {
                Text("Enable data")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.35), in: Capsule())
                    .overlay(Capsule().strokeBorder(Theme.accent, lineWidth: 1))
            }
            .accessibilityHint("Connects Health and motion data")

            if showsHealthNote {
                Text("Health & motion integration arrives in the integrations phase.")
                    .font(.caption2)
                    .foregroundStyle(Theme.warning)
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Close")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 44)
                .padding(.vertical, 15)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.surfaceStroke, lineWidth: 1))
        }
        .padding(.bottom, 12)
        .accessibilityLabel("Close sleep details")
    }
}
