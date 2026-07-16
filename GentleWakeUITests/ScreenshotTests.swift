import XCTest

/// Walks every screen in the current phase and attaches a screenshot of each.
/// CI extracts the attachments as the phase-checkpoint artifacts that get
/// compared side-by-side against the reference screenshots.
final class ScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeScreen() {
        let app = XCUIApplication()
        app.launch()
        waitForHome(app)
        snap(app, "01-home-alarm-off")
    }

    @MainActor
    func testAlarmToggledOn() {
        let app = XCUIApplication()
        app.launch()
        waitForHome(app)
        app.buttons["Alarm"].tap()
        snap(app, "02-home-alarm-on")
        // Leave the store as we found it.
        app.buttons["Alarm"].tap()
    }

    @MainActor
    func testProfileSheet() {
        let app = XCUIApplication()
        app.launch()
        waitForHome(app)
        app.buttons["Profile"].tap()
        sleepBriefly()
        snap(app, "03-profile-stub")
    }

    @MainActor
    func testNextSleepSheet() {
        let app = XCUIApplication()
        app.launch()
        waitForHome(app)
        let pill = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Sleep duration'")
        ).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 5))
        pill.tap()
        sleepBriefly()
        snap(app, "04-next-sleep-stub")
    }

    @MainActor
    func testAlarmOptionsSheet() {
        let app = XCUIApplication()
        app.launch()
        waitForHome(app)
        app.buttons["Alarm options"].tap()
        sleepBriefly()
        snap(app, "05-alarm-options-stub")
    }

    /// Home at an accessibility Dynamic Type size — layout must not break.
    @MainActor
    func testHomeAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL",
        ]
        app.launch()
        waitForHome(app)
        snap(app, "06-home-dynamic-type-axL")
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
        // Let sheet presentation animation settle before capturing.
        Thread.sleep(forTimeInterval: 0.8)
    }
}
