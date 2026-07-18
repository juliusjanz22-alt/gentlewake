import SwiftUI

/// The wake screen (ringing + nudging phases): "Time to rise!", the time,
/// a glowing orb with an animated waveform, and the dismiss pill.
///
/// The reference orb has a smiling face — that reads as a brand mascot, so
/// this placeholder keeps the glow without the face. Dismiss control is
/// INFERRED (no reference shows the ringing screen's buttons); the source
/// material shows no snooze anywhere, so none is built.
struct RingingView: View {
    @Environment(AlarmCoordinator.self) private var coordinator
    let settings: AlarmSettings

    private var isNudging: Bool {
        coordinator.phase == .nudging
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                Text("Time to rise!")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(Int(coordinator.clock.now.minutesOfDay).asClockTime)
                        .font(.system(size: 64, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.top, 4)

                orbWithWaveform
                    .padding(.top, 40)

                if isNudging {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.and.waves.left.and.right.fill")
                            .font(.footnote)
                        Text("Nudge fail-safe active")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(Theme.warning)
                    .glassPill(horizontalPadding: 14, verticalPadding: 8)
                    .padding(.top, 30)
                }

                Spacer()

                Button {
                    coordinator.dismissAlarm()
                    Haptics.toggle()
                } label: {
                    Text("I'm awake")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 54)
                        .padding(.vertical, 17)
                        .background(Theme.accent, in: Capsule())
                        .shadow(color: Theme.accent.opacity(0.35), radius: 16, y: 6)
                }
                .padding(.bottom, 40)
                .accessibilityHint("Stops the alarm")
            }
        }
    }

    /// Clean sunrise motif: a soft accent ring with a filled orange disc that
    /// gently breathes, over a thin animated waveform line.
    private var orbWithWaveform: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                WaveformShape(phase: t * 2.2, amplitude: isNudging ? 14 : 8)
                    .stroke(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(height: 56)
                    .padding(.horizontal, 40)

                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 168, height: 168)
                    .scaleEffect(1 + 0.03 * sin(t * (isNudging ? 6 : 2.5)))

                Circle()
                    .fill(Theme.accent)
                    .frame(width: 108, height: 108)
                    .overlay(
                        Image(systemName: isNudging ? "bell.fill" : "sun.max.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(.white)
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

/// One horizontal sine cycle across the width; phase animates the travel.
struct WaveformShape: Shape {
    var phase: Double
    var amplitude: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let steps = 90
        path.move(to: CGPoint(x: rect.minX, y: midY))
        for i in 1...steps {
            let x = rect.minX + rect.width * Double(i) / Double(steps)
            let relative = Double(i) / Double(steps)
            // Taper the ends so the wave fades out at the edges.
            let envelope = sin(relative * .pi)
            let y = midY + sin(relative * 4 * .pi + phase) * amplitude * envelope
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}
