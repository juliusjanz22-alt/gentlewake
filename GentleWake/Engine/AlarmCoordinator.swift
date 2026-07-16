import Foundation
import Observation
import UIKit

/// The alarm engine's state machine. Ticks against the injected clock and
/// walks the sleep window through its phases:
///
///   idle → sleeping (bedtime) → fading (wake − fadeIn) → ringing (wake)
///        → nudging (wake + nudgeDelay, tier 2) → dismissed by the user.
///
/// Tier 1 is the fade itself, tier 2 the nudge timbre, tier 3 the
/// notification chain scheduled independently of this in-process machine.
@Observable
final class AlarmCoordinator {
    enum Phase: Equatable {
        case idle
        case sleeping
        case fading
        case ringing
        case nudging
        /// Post-dismiss morning brief; exits via finishBrief().
        case brief
    }

    private(set) var phase: Phase = .idle
    /// Fade progress 0–1 while fading (drives the sleep screen's progress).
    private(set) var fadeProgress: Double = 0

    let clock: AppClock
    private let synth = ToneSynth()
    private let liveActivity = LiveActivityController()
    private var timer: Timer?
    private var settingsProvider: (() -> AlarmSettings?)?
    /// Set when the user ends sleep mode manually; suppresses re-entry until
    /// the sleep window is exited.
    private var sleepUIDismissed = false
    /// Minutes after wake before the nudge tier takes over.
    static let nudgeDelayMinutes = 3.0
    /// Ringing gives up (and goes idle) an hour past wake.
    static let ringTimeoutMinutes = 60.0

    var showsSleepUI: Bool {
        phase != .idle
    }

    init(clock: AppClock = ClockFactory.make()) {
        self.clock = clock
    }

    // MARK: - Lifecycle

    func attach(settingsProvider: @escaping () -> AlarmSettings?) {
        self.settingsProvider = settingsProvider
        startTicking()
    }

    private func startTicking() {
        guard timer == nil else { return }
        // Scaled clocks tick faster so compressed fades stay smooth.
        let interval = max(0.05, 0.5 / clock.scale)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    // MARK: - User actions

    func armed(_ settings: AlarmSettings) {
        sleepUIDismissed = false
        Task {
            let skipAuth = UserDefaults.standard.bool(forKey: "UITestSkipNotifAuth")
            if !skipAuth {
                _ = await NotificationBackup.requestAuthorization()
                await NotificationBackup.schedule(wakeMinutes: settings.wakeMinutes)
            }
        }
    }

    func disarmed() {
        stopAllAudio()
        phase = .idle
        Task { await NotificationBackup.cancel() }
    }

    /// Called with (settings, wakeDate) when the user dismisses the alarm;
    /// the host inserts a SleepSession so tracking works offline.
    var recordSession: ((AlarmSettings, Date) -> Void)?

    /// Called with fade progress (0–1) each tick while fading; the host
    /// drives the HomeKit sunrise from it when enabled.
    var sunriseUpdate: ((Double) -> Void)?

    /// User confirmed they're awake on the ringing screen. Hands off to the
    /// morning brief if any of its panels are enabled.
    func dismissAlarm() {
        let settings = settingsProvider.flatMap { $0() }
        if let settings {
            recordSession?(settings, clock.now)
        }
        stopAllAudio()
        Task { await NotificationBackup.cancel() }

        let wantsBrief = settings.map {
            $0.briefCalendar || $0.briefWeather || $0.briefReminders
        } ?? false
        if wantsBrief {
            phase = .brief
        } else {
            sleepUIDismissed = true
            phase = .idle
        }
    }

    /// Leaves the morning brief and returns home.
    func finishBrief() {
        sleepUIDismissed = true
        phase = .idle
    }

    /// User left sleep mode early (alarm stays armed).
    func endSleepModeEarly() {
        stopAllAudio()
        sleepUIDismissed = true
        phase = .idle
    }

    // MARK: - Tick

    private func tick() {
        guard let provider = settingsProvider,
              let settings = provider(),
              settings.isEnabled else {
            if phase != .idle {
                stopAllAudio()
                phase = .idle
            }
            return
        }

        // The brief isn't time-driven; it stays up until the user leaves it.
        if phase == .brief {
            return
        }

        let duration = Double(settings.sleepDurationMinutes)
        let fadeLength = min(Double(settings.fadeInMinutes), duration)
        let nowMinutes = clock.now.minutesOfDay
        // Position inside the window, wrap-aware, in minutes since bedtime.
        let rel = (nowMinutes - Double(settings.bedtimeMinutes) + 1440)
            .truncatingRemainder(dividingBy: 1440)

        let fadeStart = duration - fadeLength
        let nudgeAt = duration + Self.nudgeDelayMinutes
        let timeoutAt = duration + Self.ringTimeoutMinutes

        let target: Phase
        switch rel {
        case ..<fadeStart:
            target = .sleeping
        case ..<duration:
            target = .fading
        case ..<nudgeAt:
            target = .ringing
        case ..<timeoutAt:
            target = settings.nudgeEnabled ? .nudging : .ringing
        default:
            target = .idle
        }

        // Manual dismissal suppresses the sleep UI until the window resets.
        if sleepUIDismissed {
            if target == .idle || rel >= timeoutAt {
                sleepUIDismissed = false
            } else {
                setPhase(.idle, settings: settings)
                return
            }
        }

        if target == .fading {
            let curve = FadeCurve(rawValue: settings.fadeCurve) ?? .gentle
            let t = fadeLength > 0 ? (rel - fadeStart) / fadeLength : 1
            fadeProgress = min(1, max(0, t))
            let level = settings.startVolume
                + (settings.endVolume - settings.startVolume) * curve.volume(at: fadeProgress)
            synth.volume = Float(level)
            if settings.sunriseEnabled {
                sunriseUpdate?(fadeProgress)
            }
        }

        setPhase(target, settings: settings)

        if phase != .idle && phase != .brief {
            liveActivity.update(
                phaseName: phaseName(phase),
                progress: fadeProgress,
                wakeTimeText: settings.wakeMinutes.asClockTime
            )
        }
    }

    private func phaseName(_ phase: Phase) -> String {
        switch phase {
        case .idle: "idle"
        case .sleeping: "sleeping"
        case .fading: "fading"
        case .ringing: "ringing"
        case .nudging: "nudging"
        case .brief: "brief"
        }
    }

    private func setPhase(_ newPhase: Phase, settings: AlarmSettings) {
        guard newPhase != phase else { return }
        let oldPhase = phase
        phase = newPhase

        // begin() self-guards against double-starts; calling it on every
        // active phase covers windows entered mid-flight (app opened during
        // the fade, not at bedtime).
        if newPhase != .idle && newPhase != .brief {
            liveActivity.begin(
                bedtimeText: settings.bedtimeMinutes.asClockTime,
                wakeTimeText: settings.wakeMinutes.asClockTime
            )
        }

        switch newPhase {
        case .idle, .brief:
            stopAllAudio()
            liveActivity.end()
        case .sleeping:
            // Near-silent keepalive holds the audio session (and the app)
            // alive through the locked sleep window.
            synth.play(soundID: effectiveSoundID(settings), nudge: false)
            synth.volume = 0.0001
        case .fading:
            if oldPhase != .sleeping {
                synth.play(soundID: effectiveSoundID(settings), nudge: false)
            }
            synth.volume = Float(settings.startVolume)
        case .ringing:
            if oldPhase != .fading && oldPhase != .sleeping {
                synth.play(soundID: effectiveSoundID(settings), nudge: false)
            }
            synth.volume = Float(settings.endVolume)
        case .nudging:
            synth.play(soundID: effectiveSoundID(settings), nudge: true)
            synth.volume = Float(max(settings.endVolume, 0.9))
        }

        UIApplication.shared.isIdleTimerDisabled = (newPhase != .idle)
    }

    private func stopAllAudio() {
        synth.stop()
        fadeProgress = 0
    }

    /// Random mode picks a deterministic sound per calendar day from the
    /// nature + melody pools (nudge cues stay reserved for tier 2).
    private func effectiveSoundID(_ settings: AlarmSettings) -> String {
        guard settings.randomSoundMode else { return settings.soundID }
        let pool = SoundCatalog.nature + SoundCatalog.melodies
        let day = Calendar.current.ordinality(of: .day, in: .era, for: clock.now) ?? 0
        return pool[day % pool.count].id
    }
}
