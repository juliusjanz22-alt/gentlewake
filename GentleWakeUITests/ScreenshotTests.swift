import XCTest

/// Walks every screen and attaches a screenshot of each; CI extracts the
/// attachments as phase-checkpoint artifacts compared against the reference
/// screenshots. The Z-prefixed tests run last (alphabetical order) and
/// exercise the LIVE alarm engine — time-compressed via the debug clock —
/// rather than static UI.
final class ScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// Launches with a scenario; `clean` resets persisted state so every
    /// screenshot is deterministic regardless of test order.
    @MainActor
    private func launchApp(scenario: String = "clean", extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments =
            ["-UITestScenario", scenario, "-UITestSkipNotifAuth", "YES"] + extraArgs
        app.launch()
        return app
    }

    // MARK: - Static screens

    @MainActor
    func testHomeScreen() {
        let app = launchApp()
        waitForHome(app)
        snap(app, "01-home-alarm-off")
    }

    @MainActor
    func testAlarmToggledOn() {
        let app = launchApp()
        waitForHome(app)
        app.buttons["Alarm"].tap()
        snap(app, "02-home-alarm-on")
        app.buttons["Alarm"].tap()
    }

    @MainActor
    func testProfileSheet() {
        let app = launchApp()
        waitForHome(app)
        app.buttons["Profile"].tap()
        sleepBriefly()
        snap(app, "03-profile")

        app.buttons["Morning brief"].tap()
        sleepBriefly()
        snap(app, "17-morning-brief-settings")
        app.navigationBars.buttons.firstMatch.tap() // back
        sleepBriefly()

        app.buttons["FAQ & Feedback"].tap()
        sleepBriefly()
        // Expand the first FAQ entry so the answer style gets captured.
        app.buttons["Why wake up gradually?"].tap()
        sleepBriefly()
        snap(app, "18-faq")
    }

    @MainActor
    func testNextSleepSheet() {
        let app = launchApp()
        waitForHome(app)
        let pill = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Sleep duration'")
        ).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 5))
        pill.tap()
        sleepBriefly()
        snap(app, "04-next-sleep")
    }

    @MainActor
    func testAlarmOptionsSheet() {
        let app = launchApp()
        waitForHome(app)
        app.buttons["Alarm options"].tap()
        sleepBriefly()
        snap(app, "05-alarm-options")
    }

    @MainActor
    func testHomeAtAccessibilityTextSize() {
        let app = launchApp(extraArgs: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL",
        ])
        waitForHome(app)
        snap(app, "06-home-dynamic-type-axL")
    }

    @MainActor
    func testSoundLibrary() {
        let app = launchApp()
        waitForHome(app)
        app.buttons["Alarm options"].tap()
        sleepBriefly()

        let soundRow = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Alarm sound'")
        ).firstMatch
        XCTAssertTrue(soundRow.waitForExistence(timeout: 5))
        soundRow.tap()
        sleepBriefly()
        snap(app, "07-sound-library")

        let alps = app.buttons["Alps"]
        XCTAssertTrue(alps.waitForExistence(timeout: 5))
        alps.tap()
        sleepBriefly()
        snap(app, "08-sound-library-selected")

        app.swipeUp()
        app.swipeUp()
        snap(app, "09-sound-library-nudge-section")
    }

    // MARK: - Live alarm engine (time-compressed)

    /// Full sleep cycle at 60× speed: bedtime 23:00 → fade from 23:05 →
    /// ring at 23:10 → nudge at 23:13, then dismiss. One scaled minute per
    /// real second, so the whole night takes ~20 seconds.
    @MainActor
    func testZSleepCycleLive() {
        let app = launchApp(scenario: "sleepCycle", extraArgs: [
            "-DebugClockStartMinutes", "1378", // 22:58
            "-DebugClockScale", "60",
        ])

        XCTAssertTrue(
            app.staticTexts["Sleep well!"].waitForExistence(timeout: 15),
            "Sleep mode never appeared at bedtime"
        )
        snap(app, "10-sleep-mode")

        XCTAssertTrue(
            app.staticTexts["Rising gently"].waitForExistence(timeout: 20),
            "Fade phase never started"
        )
        snap(app, "11-sleep-fading")

        XCTAssertTrue(
            app.staticTexts["Time to rise!"].waitForExistence(timeout: 20),
            "Ringing screen never appeared at wake time"
        )
        snap(app, "12-ringing")

        XCTAssertTrue(
            app.staticTexts["Nudge fail-safe active"].waitForExistence(timeout: 20),
            "Nudge tier never engaged"
        )
        snap(app, "13-ringing-nudge")

        app.buttons["I'm awake"].tap()
        XCTAssertTrue(
            app.staticTexts["Good morning!"].waitForExistence(timeout: 10),
            "Morning brief never appeared after dismissing the alarm"
        )
        snap(app, "14-morning-brief")

        app.buttons["Start the day"].tap()
        XCTAssertTrue(
            app.buttons["Alarm"].waitForExistence(timeout: 10),
            "Leaving the morning brief did not return home"
        )
        snap(app, "15-home-after-dismiss")
    }

    /// Tier 3: backup notifications actually deliver. Schedules the chain on
    /// a 12-second fuse, backgrounds the app, and waits for the banner on
    /// the springboard.
    @MainActor
    func testZZBackupNotificationChain() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let app = XCUIApplication()
        app.launchArguments = ["-UITestScenario", "backupChain"]
        app.launch()

        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 8) {
            allow.tap()
        }

        XCUIDevice.shared.press(.home)

        let banner = springboard.staticTexts["Time to rise!"]
        XCTAssertTrue(
            banner.waitForExistence(timeout: 45),
            "Backup notification banner never arrived"
        )
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "16-backup-notification-banner"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - Helpers

    @MainActor
    private func waitForHome(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Alarm"].waitForExistence(timeout: 10), "Home screen did not appear")
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func sleepBriefly() {
        Thread.sleep(forTimeInterval: 0.8)
    }
}
