import SwiftUI
import SwiftData

/// Alarm configuration sheet: sound selection, fade-in duration and curve,
/// start/end volume, and the nudge fail-safe.
///
/// INFERRED LAYOUT: the reference material describes these controls (PDF §3,
/// review quotes) but never shows this screen. Composed from the source's
/// card/pill design language.
struct AlarmOptionsView: View {
    @Bindable var settings: AlarmSettings
    @Environment(\.dismiss) private var dismiss

    private static let fadeDurations = [5, 10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {
                        soundRow
                        fadeCard
                        volumeCard
                        nudgeCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 90)
                }

                closeButton
            }
            .background(Theme.sheetBackground)
            .navigationTitle("Alarm settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.sheetBackground, for: .navigationBar)
            .navigationDestination(for: String.self) { destination in
                if destination == "sounds" {
                    SoundLibraryView(settings: settings)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sound

    private var soundRow: some View {
        NavigationLink(value: "sounds") {
            HStack(spacing: 14) {
                Group {
                    if let sound = SoundCatalog.sound(for: settings.soundID) {
                        SoundArtworkView(sound: sound)
                    } else {
                        Theme.surface
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Alarm sound")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    Text(currentSoundName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .accessibilityLabel("Alarm sound: \(currentSoundName)")
        .accessibilityHint("Opens the sound library")
    }

    private var currentSoundName: String {
        if settings.randomSoundMode {
            return "Random every day"
        }
        return SoundCatalog.sound(for: settings.soundID)?.name ?? "Not set"
    }

    // MARK: - Fade-in

    private var fadeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader(icon: "waveform", title: "Gentle fade-in")

            Text("Sound starts near-silent and rises over this window before your wake time.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                ForEach(Self.fadeDurations, id: \.self) { minutes in
                    selectablePill(
                        label: "\(minutes) min",
                        isSelected: settings.fadeInMinutes == minutes
                    ) {
                        settings.fadeInMinutes = minutes
                        Haptics.tick()
                    }
                }
            }

            Text("Rise curve")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                ForEach(FadeCurve.allCases) { curve in
                    curvePill(curve)
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
    }

    private func curvePill(_ curve: FadeCurve) -> some View {
        let isSelected = settings.fadeCurve == curve.rawValue
        return Button {
            settings.fadeCurve = curve.rawValue
            Haptics.tick()
        } label: {
            VStack(spacing: 6) {
                FadeCurveShape(curve: curve)
                    .stroke(
                        isSelected ? Theme.accentBright : Theme.textSecondary,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 44, height: 22)
                Text(curve.label)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Theme.accent.opacity(0.25) : Color.white.opacity(0.03),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : Theme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(curve.label) rise curve")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Volume

    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader(icon: "speaker.wave.2.fill", title: "Volume")

            volumeSlider(
                label: "Start volume",
                value: $settings.startVolume,
                icon: "speaker.fill"
            )
            volumeSlider(
                label: "End volume",
                value: $settings.endVolume,
                icon: "speaker.wave.3.fill"
            )
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
    }

    private func volumeSlider(label: String, value: Binding<Double>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
            }
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Slider(value: value, in: 0...1)
                    .tint(Theme.accent)
                    .accessibilityLabel(label)
                    .accessibilityValue("\(Int(value.wrappedValue * 100)) percent")
            }
        }
    }

    // MARK: - Nudge fail-safe

    private var nudgeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $settings.nudgeEnabled) {
                cardHeader(icon: "bell.and.waves.left.and.right.fill", title: "Nudge fail-safe")
            }
            .tint(Theme.accent)

            Text("If you sleep through the fade-in, a brighter nudge melody takes over. A native backup alarm always stands behind both layers.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Shared bits

    private func cardHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Theme.accentBright)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func selectablePill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? Theme.accent.opacity(0.3) : Color.white.opacity(0.03),
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? Theme.accent : Theme.surfaceStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
        .accessibilityLabel("Close alarm settings")
    }
}

/// Mini preview of a fade curve for the selector pills.
struct FadeCurveShape: Shape {
    let curve: FadeCurve

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        let steps = 24
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            path.addLine(to: CGPoint(
                x: rect.minX + rect.width * t,
                y: rect.maxY - rect.height * curve.volume(at: t)
            ))
        }
        return path
    }
}
