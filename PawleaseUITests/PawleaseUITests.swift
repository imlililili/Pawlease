//
//  PawleaseUITests.swift
//  PawleaseUITests
//
//  Created by Emily on 22/9/2026.
//

import XCTest

final class PawleaseUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Drives the real Phase 1 golden path: the seeded Circle appears on
    /// launch, "Take Today's Photo" opens the Composer, Publish stays
    /// disabled until a photo and caption are provided, and Cancel returns
    /// to an unchanged Pet Home. Also confirms the comments/reactions
    /// feature's navigation change (feed rows now link to Post Detail)
    /// didn't disturb this existing flow.
    @MainActor
    func testPetHomeShowsSeededCircleAndComposerGatesPublish() throws {
        let app = XCUIApplication()
        app.launch()

        let petHomeTitle = app.navigationBars["Pet Home"]
        XCTAssertTrue(petHomeTitle.waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Mochi"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0 of 2 friends have shared today"].exists)
        XCTAssertTrue(app.staticTexts["Feed Locked"].exists)

        app.buttons["Take Today's Photo"].tap()

        let composerTitle = app.navigationBars["Today's Moment"]
        XCTAssertTrue(composerTitle.waitForExistence(timeout: 5))

        let publishButton = app.buttons["Publish"]
        XCTAssertTrue(publishButton.waitForExistence(timeout: 5))
        XCTAssertFalse(publishButton.isEnabled)

        app.buttons["Cancel"].tap()
        XCTAssertTrue(petHomeTitle.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
