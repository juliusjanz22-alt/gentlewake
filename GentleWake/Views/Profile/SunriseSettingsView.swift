import HomeKit
import SwiftUI
import SwiftData

/// Smart-light sunrise configuration (PDF §3: Apple Home light sync). No
/// reference screenshot exists — layout INFERRED from the source's design
/// language. In the simulator/CI this renders the empty state; real bulbs
/// require a device with a Home set up.
struct SunriseSettingsView: View {
    @Bindable var settings: AlarmSettings
    @Environment(HomeStore.self) private var homeStore

    private var selectedIDs: Set<String> {
        Set(settings.sunriseAccessoryIDs.split(separator: ",").map(String.init))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Toggle(isOn: $settings.sunriseEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "sunrise.fill")
                            .foregroundStyle(Theme.warning)
                        Text("Smart light sunrise")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .tint(Theme.accent)
                .padding(16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.surfaceStroke, lineWidth: 1)
                )

                Text("During the fade-in, your bedroom lights slowly fill the room with light — syncing visual and auditory waking.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if settings.sunriseEnabled {
                    lightsSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .background(Theme.sheetBackground)
        .navigationTitle("Light sunrise")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if settings.sunriseEnabled {
                homeStore.connect()
            }
        }
        .onChange(of: settings.sunriseEnabled) { _, enabled in
            if enabled {
                homeStore.connect()
            }
        }
    }

    @ViewBuilder
    private var lightsSection: some View {
        if homeStore.isLoading {
            ProgressView("Looking for lights…")
                .tint(Theme.accentBright)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 20)
        } else if homeStore.lights.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "lightbulb.slash")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
                Text("No compatible lights found")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Add smart bulbs (like Philips Hue) in the Home app, then pick them here.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Theme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            VStack(spacing: 10) {
                ForEach(homeStore.lights, id: \.uniqueIdentifier) { light in
                    lightRow(light)
                }
            }
        }
    }

    private func lightRow(_ light: HMAccessory) -> some View {
        let id = light.uniqueIdentifier.uuidString
        let isSelected = selectedIDs.contains(id)
        return Button {
            var ids = selectedIDs
            if isSelected {
                ids.remove(id)
            } else {
                ids.insert(id)
            }
            settings.sunriseAccessoryIDs = ids.sorted().joined(separator: ",")
            Haptics.tick()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(isSelected ? Theme.warning : Theme.textSecondary)
                Text(light.name)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(light.name)
        .accessibilityValue(isSelected ? "Selected for sunrise" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
