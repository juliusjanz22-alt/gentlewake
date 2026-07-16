import SwiftUI
import SwiftData

/// The home screen's 24-hour dial. A glowing arc spans the sleep window from
/// the bedtime handle (moon) clockwise to the wake handle (alarm). Both
/// handles drag; dragging the arc body shifts the whole window.
struct SleepDialView: View {
    @Bindable var settings: AlarmSettings
    var openAlarmOptions: () -> Void

    private enum DragMode {
        case bed, wake, shift
    }

    @State private var dragMode: DragMode?
    @State private var dragStartBed = 0
    @State private var dragStartWake = 0
    @State private var dragStartMinute = 0
    @State private var lastHapticSnapshot = -1

    /// Sleep window is kept between 30 minutes and 23.5 hours.
    private static let minDuration = 30
    private static let maxDuration = 1410
    private static let snapMinutes = 5
    /// How close (in dial minutes) a touch must start to a handle to grab it.
    private static let grabTolerance = 55

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let ringWidth = side * 0.088
            let ringRadius = side / 2 - ringWidth / 2

            ZStack {
                ring(ringRadius: ringRadius, ringWidth: ringWidth)
                endTicks(center: center, ringRadius: ringRadius, ringWidth: ringWidth)
                tickMarks(center: center, radius: ringRadius - ringWidth / 2 - side * 0.045)
                numerals(center: center, radius: ringRadius - ringWidth / 2 - side * 0.105, side: side)
                centerContent(side: side)
                handles(center: center, ringRadius: ringRadius, side: side)
            }
            .contentShape(Rectangle())
            .gesture(dialGesture(center: center, ringRadius: ringRadius, ringWidth: ringWidth))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Ring + arc

    private func ring(ringRadius: CGFloat, ringWidth: CGFloat) -> some View {
        let bedFraction = Double(settings.bedtimeMinutes) / 1440
        let sweepFraction = Double(settings.sleepDurationMinutes) / 1440
        // Color order is reversed relative to the visual sweep: AngularGradient
        // angles run opposite to Circle.trim's direction here (verified against
        // CI screenshots), so listing bright-first lands deep at the bedtime
        // end and bright at the wake end, matching the reference.
        let gradient = AngularGradient(
            colors: [Theme.accentBright, Theme.accent, Theme.accentDeep],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(sweepFraction * 360)
        )

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.055), lineWidth: ringWidth)

            // Glow layer behind the arc
            Circle()
                .trim(from: 0, to: sweepFraction)
                .stroke(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: ringWidth * 1.25, lineCap: .round))
                .rotationEffect(.degrees(bedFraction * 360 - 90))
                .blur(radius: 14)

            Circle()
                .trim(from: 0, to: sweepFraction)
                .stroke(gradient, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                .rotationEffect(.degrees(bedFraction * 360 - 90))
        }
        .frame(width: ringRadius * 2, height: ringRadius * 2)
    }

    /// Short white radial ticks marking the exact ends of the sleep arc.
    private func endTicks(center: CGPoint, ringRadius: CGFloat, ringWidth: CGFloat) -> some View {
        ForEach([settings.bedtimeMinutes, settings.wakeMinutes], id: \.self) { minutes in
            Capsule()
                .fill(Color.white.opacity(0.9))
                .frame(width: 2.5, height: ringWidth * 0.5)
                .rotationEffect(.degrees(Double(minutes) / 1440 * 360))
                .position(point(at: minutes, radius: ringRadius, center: center))
        }
        .accessibilityHidden(true)
    }

    // MARK: - Ticks + numerals

    private func tickMarks(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(0..<96, id: \.self) { index in
            let isHour = index % 4 == 0
            Circle()
                .fill(Color.white.opacity(isHour ? 0.32 : 0.15))
                .frame(width: isHour ? 3 : 2, height: isHour ? 3 : 2)
                .position(point(at: index * 15, radius: radius, center: center))
        }
        .accessibilityHidden(true)
    }

    private func numerals(center: CGPoint, radius: CGFloat, side: CGFloat) -> some View {
        ForEach(Array(stride(from: 0, through: 22, by: 2)), id: \.self) { hour in
            Text("\(hour)")
                .font(.system(size: side * 0.038, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color.white.opacity(0.35))
                .position(point(at: hour * 60, radius: radius, center: center))
        }
        .accessibilityHidden(true)
    }

    // MARK: - Center

    private func centerContent(side: CGFloat) -> some View {
        VStack(spacing: side * 0.03) {
            HStack(spacing: 5) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: side * 0.04))
                Text("Alarm")
                    .font(.system(size: side * 0.048, weight: .medium))
            }
            .foregroundStyle(Theme.textSecondary)

            Text(settings.wakeMinutes.asClockTime)
                .font(.system(size: side * 0.115, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())

            Button(action: openAlarmOptions) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: side * 0.045, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, side * 0.06)
                    .padding(.vertical, side * 0.026)
                    .background(Theme.surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(Theme.surfaceStroke, lineWidth: 1))
            }
            .accessibilityLabel("Alarm options")
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Handles

    private func handles(center: CGPoint, ringRadius: CGFloat, side: CGFloat) -> some View {
        let handleSize = side * 0.105

        return ZStack {
            // Bedtime (moon)
            ZStack {
                Circle().fill(Color(hex: 0x2A1E44))
                Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                Image(systemName: "moon.fill")
                    .font(.system(size: handleSize * 0.45))
                    .foregroundStyle(Theme.accentBright)
            }
            .frame(width: handleSize, height: handleSize)
            .shadow(color: Theme.accentDeep.opacity(0.8), radius: 8)
            .position(point(at: settings.bedtimeMinutes, radius: ringRadius, center: center))
            .accessibilityElement()
            .accessibilityLabel("Bedtime")
            .accessibilityValue(settings.bedtimeMinutes.asClockTime)
            .accessibilityHint("Adjust to change when your sleep window starts")
            .accessibilityAdjustableAction { direction in
                adjustBed(by: direction == .increment ? 15 : -15)
            }

            // Wake (alarm)
            ZStack {
                Circle().fill(Color(hex: 0xEDE7FF))
                Image(systemName: "alarm.fill")
                    .font(.system(size: handleSize * 0.48))
                    .foregroundStyle(Theme.accentDeep)
            }
            .frame(width: handleSize, height: handleSize)
            .shadow(color: Theme.accent.opacity(0.9), radius: 10)
            .position(point(at: settings.wakeMinutes, radius: ringRadius, center: center))
            .accessibilityElement()
            .accessibilityLabel("Wake-up time")
            .accessibilityValue(settings.wakeMinutes.asClockTime)
            .accessibilityHint("Adjust to change when the alarm fades in")
            .accessibilityAdjustableAction { direction in
                adjustWake(by: direction == .increment ? 15 : -15)
            }
        }
    }

    // MARK: - Interaction

    private func dialGesture(center: CGPoint, ringRadius: CGFloat, ringWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let touchMinute = minute(at: value.location, center: center)

                if dragMode == nil {
                    let radial = hypot(value.location.x - center.x, value.location.y - center.y)
                    guard abs(radial - ringRadius) < ringWidth * 2.2 else { return }

                    let bedDistance = angularDistance(touchMinute, settings.bedtimeMinutes)
                    let wakeDistance = angularDistance(touchMinute, settings.wakeMinutes)

                    if wakeDistance <= Self.grabTolerance && wakeDistance <= bedDistance {
                        dragMode = .wake
                    } else if bedDistance <= Self.grabTolerance {
                        dragMode = .bed
                    } else if isWithinSleepWindow(touchMinute) {
                        dragMode = .shift
                    } else {
                        return
                    }
                    dragStartBed = settings.bedtimeMinutes
                    dragStartWake = settings.wakeMinutes
                    dragStartMinute = touchMinute
                }

                switch dragMode {
                case .wake:
                    setWake(snap(touchMinute))
                case .bed:
                    setBed(snap(touchMinute))
                case .shift:
                    let delta = signedDelta(from: dragStartMinute, to: touchMinute)
                    settings.bedtimeMinutes = snap(dragStartBed + delta)
                    settings.wakeMinutes = snap(dragStartWake + delta)
                case nil:
                    break
                }
                tickHapticIfChanged()
            }
            .onEnded { _ in
                dragMode = nil
            }
    }

    private func setWake(_ minutes: Int) {
        let duration = (minutes - settings.bedtimeMinutes + 1440) % 1440
        guard duration >= Self.minDuration && duration <= Self.maxDuration else { return }
        settings.wakeMinutes = minutes
    }

    private func setBed(_ minutes: Int) {
        let duration = (settings.wakeMinutes - minutes + 1440) % 1440
        guard duration >= Self.minDuration && duration <= Self.maxDuration else { return }
        settings.bedtimeMinutes = minutes
    }

    private func adjustWake(by delta: Int) {
        setWake((settings.wakeMinutes + delta).wrappedToDay)
    }

    private func adjustBed(by delta: Int) {
        setBed((settings.bedtimeMinutes + delta).wrappedToDay)
    }

    private func tickHapticIfChanged() {
        let snapshot = settings.bedtimeMinutes * 1440 + settings.wakeMinutes
        if snapshot != lastHapticSnapshot {
            lastHapticSnapshot = snapshot
            Haptics.tick()
        }
    }

    // MARK: - Geometry

    /// Point on the dial for a minutes-from-midnight value; 0 is at the top,
    /// time proceeds clockwise.
    private func point(at minutes: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let theta = Double(minutes) / 1440 * 2 * .pi
        return CGPoint(
            x: center.x + radius * sin(theta),
            y: center.y - radius * cos(theta)
        )
    }

    private func minute(at location: CGPoint, center: CGPoint) -> Int {
        let theta = atan2(location.x - center.x, -(location.y - center.y))
        let fraction = theta / (2 * .pi)
        return Int((fraction * 1440).rounded()).wrappedToDay
    }

    private func snap(_ minutes: Int) -> Int {
        let snapped = Int((Double(minutes) / Double(Self.snapMinutes)).rounded()) * Self.snapMinutes
        return snapped.wrappedToDay
    }

    /// Shortest wrap-aware distance between two dial positions, in minutes.
    private func angularDistance(_ a: Int, _ b: Int) -> Int {
        let diff = abs(a - b) % 1440
        return min(diff, 1440 - diff)
    }

    private func signedDelta(from: Int, to: Int) -> Int {
        ((to - from + 720 + 1440) % 1440) - 720
    }

    private func isWithinSleepWindow(_ minutes: Int) -> Bool {
        let fromBed = (minutes - settings.bedtimeMinutes + 1440) % 1440
        return fromBed <= settings.sleepDurationMinutes
    }
}
