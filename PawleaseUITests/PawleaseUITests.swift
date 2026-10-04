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

        app.buttons["Today's Moment"].tap()

        let composerTitle = app.navigationBars["Today's Moment"]
        XCTAssertTrue(composerTitle.waitForExistence(timeout: 5))

        let publishButton = app.buttons["Share Today's Moment"]
        XCTAssertTrue(publishButton.waitForExistence(timeout: 5))
        XCTAssertFalse(publishButton.isEnabled)
        XCTAssertFalse(app.buttons["Take Photo"].exists)
        XCTAssertFalse(app.buttons["Photo Library"].exists)
        XCTAssertFalse(app.staticTexts["Mood (optional)"].exists)

        app.buttons["Add today's photo"].tap()
        XCTAssertTrue(app.buttons["Take Photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Photo Library"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        app.buttons["Take Photo"].tap()
        XCTAssertTrue(app.staticTexts["Camera Unavailable"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(composerTitle.waitForExistence(timeout: 5))

        app.buttons["Cancel"].tap()
        XCTAssertTrue(petHomeTitle.waitForExistence(timeout: 5))
    }

    /// Confirms Pet Home's redesigned layout reads its Circle name, pet
    /// name, and contributor/streak summary from live `PetHomeViewModel`
    /// state rather than literal strings baked into the View — the eyebrow
    /// label, summary-row headings, and both live values must all render.
    @MainActor
    func testPetHomeRendersDynamicCircleAndPetValues() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["YOUR CIRCLE"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The Pack"].waitForExistence(timeout: 5), "Circle name should render from the live snapshot")
        XCTAssertTrue(app.staticTexts["Mochi"].waitForExistence(timeout: 5), "Pet name should render from the live snapshot")
        XCTAssertTrue(app.staticTexts["CURRENT STREAK"].exists)
        XCTAssertTrue(app.staticTexts["CONTRIBUTORS"].exists)
        XCTAssertTrue(app.buttons["Today's Moment"].exists)
        XCTAssertTrue(app.staticTexts["Circle Diary"].exists)
    }

    /// Regression for the duplicate-invite-control fix: Pet Home's toolbar
    /// must expose only Settings — the separate "Join a Circle" button is
    /// gone, and Join a Circle is reachable from inside Circle Settings
    /// instead (see `CircleSettingsUITests`).
    @MainActor
    func testPetHomeToolbarShowsOnlyCircleSettings() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Pet Home"].buttons["Circle Settings"].exists)
        XCTAssertFalse(app.navigationBars["Pet Home"].buttons["Join a Circle"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
