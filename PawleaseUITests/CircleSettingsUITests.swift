import XCTest

/// Focused UI coverage for the redesigned Circle Settings screen: it's
/// reachable from Pet Home, shows the dynamic member roster, and exposes
/// the Invite Code workflow's entry action.
final class CircleSettingsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCircleSettingsShowsMembersAndInviteCodeAction() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 5))
        app.buttons["Circle Settings"].tap()

        XCTAssertTrue(app.navigationBars["Circle Settings"].waitForExistence(timeout: 5))
        // Loading includes a real `CKContainer.accountStatus()` check,
        // which can take noticeably longer than Pet Home's own load under
        // simulator/host load — a generous timeout avoids flaking on that,
        // not on anything this screen's own content depends on.
        XCTAssertTrue(app.staticTexts["CIRCLE"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["The Pack"].exists)
        XCTAssertTrue(app.staticTexts["Mochi"].exists)

        // Three seeded demo members: "You" (Owner), "Ava", "Noah".
        XCTAssertTrue(app.staticTexts["You"].exists)
        XCTAssertTrue(app.staticTexts["Owner"].exists)
        XCTAssertTrue(app.staticTexts["Ava"].exists)
        XCTAssertTrue(app.staticTexts["Noah"].exists)

        XCTAssertTrue(app.staticTexts["INVITE CODE"].exists)
        // Either the "no code yet" button or an already-active code's Copy
        // control is present — both are legitimate, order-independent
        // states of the same preserved invite-code workflow.
        let createButton = app.buttons["Create Invite Code"]
        let copyButton = app.buttons["Copy invite code"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5) || copyButton.exists)
    }

    /// Join a Circle moved from Pet Home's toolbar into Circle Settings —
    /// confirms it's still reachable and opens the same `JoinCircleView`.
    @MainActor
    func testJoinACircleIsReachableFromCircleSettings() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 5))
        app.buttons["Circle Settings"].tap()
        XCTAssertTrue(app.navigationBars["Circle Settings"].waitForExistence(timeout: 5))

        let joinButton = app.buttons["Join a Circle"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 20))
        joinButton.tap()

        XCTAssertTrue(app.navigationBars["Join a Circle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Invite code"].exists)

        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Circle Settings"].waitForExistence(timeout: 5))
    }
}
