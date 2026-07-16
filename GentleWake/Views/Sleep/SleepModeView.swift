import SwiftUI

/// Full-screen night view while the sleep window runs (sleeping + fading
/// phases). Layout follows the reference: current time up top, glowing moon,
/// "Sleep well!", fade explanation, alarm-time pill.
struct SleepModeView: View {
    @Environment(AlarmCoordinator.self) private var coordinator
    let settings: AlarmSettings

    private var isFading: Bool {
        coordinator.phase == .fading
    }

    private var fadeStartMinutes: Int {
        (settings.wakeMinutes - min(settings.fadeInMinutes, settings.sleepDurationMinutes))
            .wrappedToDay
    }

    var body: some View {
        ZStack {
            StarfieldBackground()

            VStack(spacing: 0) {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(clockString)
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 18)
                .accessibilityLabel("Current time \(clockString)")

                Spacer()

                moon

                Text(isFading ? "Rising gently" : "Sleep well!")
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 28)

                Group {
                    if isFading {
                        Text("Your alarm is fading in — full volume by \(settings.wakeMinutes.asClockTime).")
                    } else {
                        Text("Alarm sound will start fading in from \(fadeStartMinutes.asClockTime), to gently wake you up by \(settings.wakeMinutes.asClockTime).")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)
                .padding(.top, 10)

                if isFading {
                    fadeProgressBar
                        .padding(.top, 22)
                        .padding(.horizontal, 60)
                }

                HStack(spacing: 7) {
                    Image(systemName: "alarm.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.accentBright)
                    Text(settings.wakeMinutes.asClockTime)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }
                .glassPill()
                .padding(.top, 26)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Alarm at \(settings.wakeMinutes.asClockTime)")

                Spacer()

                Button("End sleep mode") {
                    coordinator.endSleepModeEarly()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 26)
                .accessibilityHint("Returns home; the alarm stays on")
            }
        }
    }

    private var clockString: String {
        Int(coordinator.clock.now.minutesOfDay).asClockTime
    }

    private var moon: some View {
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(0.25))
                .frame(width: 150, height: 150)
                .blur(radius: 30)
            Image(systemName: "moon.fill")
                .font(.system(size: 74))
                .foregroundStyle(Theme.accentBright)
                .shadow(color: Theme.accent.opacity(0.9), radius: 24)
        }
        .accessibilityHidden(true)
    }

    private var fadeProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(
                        colors: [Theme.accentDeep, Theme.accentBright],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * coordinator.fadeProgress)
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fade-in progress")
        .accessibilityValue("\(Int(coordinator.fadeProgress * 100)) percent")
    }
}
