import AVFoundation

/// Placeholder audio: synthesizes a soft looping chord per sound id instead
/// of shipping real recordings (those swap in at final branding). The engine
/// contract — start near-silent, ramp volume smoothly, switch to a brighter
/// nudge timbre — is exactly what the real sound files will need.
final class ToneSynth {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isRunning = false

    /// Master volume (0–1). Set every tick during the fade.
    var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = max(0, min(1, newValue)) }
    }

    func start() {
        guard !isRunning else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback sounds through the silent switch and, combined with
            // the audio background mode, keeps running while locked.
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0
            try engine.start()
            isRunning = true
        } catch {
            // Simulator/CI audio can be flaky; the engine degrades to silent
            // state transitions rather than crashing the alarm flow.
            print("ToneSynth start failed: \(error)")
        }
    }

    func play(soundID: String, nudge: Bool) {
        start()
        guard isRunning else { return }
        player.stop()
        let buffer = Self.makeLoopBuffer(seed: soundID, nudge: nudge, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
    }

    func stop() {
        guard isRunning else { return }
        player.stop()
        engine.stop()
        isRunning = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Buffer synthesis

    /// A 4-second loop: root + fifth + octave sine chord with a slow tremolo.
    /// Base pitch derives from the sound id so every catalog entry is
    /// distinguishable. Nudge variant: brighter (adds major third an octave
    /// up) and pulses faster — unmistakably more insistent.
    private static func makeLoopBuffer(seed: String, nudge: Bool, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let length = AVAudioFrameCount(sampleRate * 4)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length)!
        buffer.frameLength = length

        var hash: UInt64 = 5381
        for scalar in seed.unicodeScalars {
            hash = (hash &* 33) &+ UInt64(scalar.value)
        }
        let base = 200.0 + Double(hash % 180) // 200–380 Hz root
        let tremoloRate = nudge ? 5.0 : 0.4
        let partials: [(freq: Double, amp: Double)] = nudge
            ? [(base, 0.4), (base * 1.5, 0.3), (base * 2, 0.25), (base * 2.5, 0.25)]
            : [(base, 0.5), (base * 1.5, 0.3), (base * 2, 0.2)]

        let samples = buffer.floatChannelData![0]
        for frame in 0..<Int(length) {
            let t = Double(frame) / sampleRate
            var value = 0.0
            for partial in partials {
                value += partial.amp * sin(2 * .pi * partial.freq * t)
            }
            let tremolo = 0.75 + 0.25 * sin(2 * .pi * tremoloRate * t)
            samples[frame] = Float(value * tremolo * 0.5)
        }
        return buffer
    }
}
