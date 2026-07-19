import AVFoundation
import Observation

/// Plays a short preview of a sound when the user taps it in the library, so
/// they can hear what each one is before choosing. Reuses ToneSynth (the same
/// placeholder audio the alarm uses); tapping again or tapping another sound
/// restarts cleanly, and previews auto-stop after a few seconds.
@Observable
final class SoundPreviewPlayer {
    /// The sound currently previewing, so the card can show a speaker badge.
    private(set) var playingID: String?

    private let synth = ToneSynth()
    private var stopWorkItem: DispatchWorkItem?
    private static let previewSeconds = 3.5

    func play(_ soundID: String) {
        stopWorkItem?.cancel()
        synth.play(soundID: soundID, nudge: false)
        // Comfortable, immediate level — a preview shouldn't fade in.
        synth.volume = 0.75
        playingID = soundID

        let item = DispatchWorkItem { [weak self] in
            self?.synth.stop()
            self?.playingID = nil
        }
        stopWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.previewSeconds, execute: item)
    }

    func stop() {
        stopWorkItem?.cancel()
        stopWorkItem = nil
        synth.stop()
        playingID = nil
    }
}
