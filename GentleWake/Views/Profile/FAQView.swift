import SwiftUI

/// FAQ & feedback. Answers are drawn from the source PDF's science and
/// architecture sections; the accordion layout is INFERRED (no reference
/// screenshot exists for this screen).
struct FAQView: View {
    private struct Entry: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private let entries: [Entry] = [
        Entry(
            question: "Why wake up gradually?",
            answer: "Sudden loud alarms trigger an adrenaline and cortisol surge — a fight-or-flight response that causes sleep inertia: grogginess, disorientation and anxiety. A sound that rises from near-silence lets your sleep stages cycle upward naturally, so you wake with a lower heart rate and less sensory shock."
        ),
        Entry(
            question: "What if I sleep through the fade-in?",
            answer: "Three layers stand behind each other. First the gentle fade-in. If you don't wake, a brighter nudge melody takes over a few minutes past your wake time. Behind both, backup system notifications fire around your wake time even if the app was closed overnight."
        ),
        Entry(
            question: "Does the app need an account or internet?",
            answer: "No. Everything runs on your device — no account, no cloud, no tracking. Sleep sessions are stored locally and never leave your phone."
        ),
        Entry(
            question: "How is the sleep gate calculated?",
            answer: "The sleep gate estimates the evening window when your body is primed for sleep, aligned to 90-minute sleep cycles ending at your alarm. Connecting Health and motion data refines it with your actual sleep patterns."
        ),
        Entry(
            question: "Why keep the app open at night?",
            answer: "iOS only lets the gentle fade-in play while the app is allowed to run. Sleep mode keeps a near-silent audio session alive so your wake-up can start from true silence. The notification backup covers you either way."
        ),
    ]

    @State private var expanded: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(entries) { entry in
                    entryCard(entry)
                }

                feedbackCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .background(Theme.sheetBackground)
        .navigationTitle("FAQ & Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func entryCard(_ entry: Entry) -> some View {
        let isExpanded = expanded.contains(entry.id)
        return Button {
            withAnimation(.snappy) {
                if isExpanded {
                    expanded.remove(entry.id)
                } else {
                    expanded.insert(entry.id)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(entry.question)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                if isExpanded {
                    Text(entry.answer)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.question)
        .accessibilityValue(isExpanded ? entry.answer : "")
        .accessibilityHint(isExpanded ? "Collapses the answer" : "Expands the answer")
    }

    private var feedbackCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(Theme.accentBright)
                Text("Send feedback")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("Feedback address gets wired up with final branding.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
