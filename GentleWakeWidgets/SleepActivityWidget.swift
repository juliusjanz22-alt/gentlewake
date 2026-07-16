import ActivityKit
import SwiftUI
import WidgetKit

@main
struct GentleWakeWidgets: WidgetBundle {
    var body: some Widget {
        SleepActivityWidget()
    }
}

/// Lock screen + Dynamic Island presentation of the sleep window.
/// No reference visual exists for the source app's live activity — layout is
/// INFERRED from its night-sky design language.
struct SleepActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepActivityAttributes.self) { context in
            lockScreenView(context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.03, blue: 0.09))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.isRinging ? "Rise" : "Sleep")
                            .font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: context.state.isRinging ? "sun.max.fill" : "moon.fill")
                            .foregroundStyle(accent)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(context.state.wakeTimeText)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "alarm.fill")
                            .foregroundStyle(accent)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    statusLine(context)
                }
            } compactLeading: {
                Image(systemName: context.state.isRinging ? "sun.max.fill" : "moon.fill")
                    .foregroundStyle(accent)
            } compactTrailing: {
                Text(context.state.wakeTimeText)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: context.state.isRinging ? "sun.max.fill" : "moon.fill")
                    .foregroundStyle(accent)
            }
        }
    }

    private var accent: Color {
        Color(red: 0.79, green: 0.72, blue: 1.0)
    }

    private func lockScreenView(_ context: ActivityViewContext<SleepActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text(context.state.isRinging ? "Time to rise!" : "Sleep mode")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                } icon: {
                    Image(systemName: context.state.isRinging ? "sun.max.fill" : "moon.fill")
                        .foregroundStyle(accent)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "alarm.fill")
                        .font(.caption)
                        .foregroundStyle(accent)
                    Text(context.state.wakeTimeText)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }

            statusLine(context)
        }
        .padding(14)
    }

    @ViewBuilder
    private func statusLine(_ context: ActivityViewContext<SleepActivityAttributes>) -> some View {
        if context.state.isFading {
            ProgressView(value: context.state.progress) {
                Text("Sound rising gently")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .tint(accent)
        } else if context.state.isRinging {
            Text("Your gentle wake-up is playing")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        } else {
            Text("Waking you gently from \(context.attributes.bedtimeText)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
