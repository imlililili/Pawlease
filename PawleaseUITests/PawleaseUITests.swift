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

    /// Confirms the seeded Circle opens the photo-first Moment composer,
    /// presents both capture sources only after the photo surface is tapped,
    /// and handles Simulator's missing camera without trapping the user.
    @MainActor
    func testPetHomeShowsSeededCircleAndComposerGatesPublish() throws {
        let app = XCUIApplication()
        app.launch()

        let petHomeTitle = app.navigationBars["Pet Home"]
        XCTAssertTrue(petHomeTitle.waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Mochi"].waitForExistence(timeout: 5))

        app.buttons["Take Today's Photo"].tap()

        let composerTitle = app.navigationBars["Today's Moment"]
        XCTAssertTrue(composerTitle.waitForExistence(timeout: 5))

        let publishButton = app.buttons["Publish"]
        XCTAssertTrue(publishButton.waitForExistence(timeout: 5))
        XCTAssertFalse(publishButton.isEnabled)
        XCTAssertFalse(app.buttons["Take Photo"].exists)
        XCTAssertFalse(app.buttons["Photo Library"].exists)
        XCTAssertFalse(app.staticTexts["Mood (optional)"].exists)

        app.buttons["Add today's photo"].tap()
        XCTAssertTrue(app.buttons["Take Photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Photo Library"].exists)
        app.buttons["Take Photo"].tap()
        XCTAssertTrue(app.staticTexts["Camera Unavailable"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(composerTitle.waitForExistence(timeout: 5))

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
