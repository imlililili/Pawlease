import XCTest

/// Focused UI coverage for the Circle Diary feature: opening the feed from
/// Pet Home, publishing both a permanent and a timed entry, confirming a
/// timed entry shows up in the feed with its expiration label, and
/// confirming empty text blocks publication.
final class CircleDiaryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openCircleDiary(_ app: XCUIApplication) {
        app.launch()
        XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 5))
        app.buttons["Circle Diary"].tap()
    }

    /// The "New Diary Entry" action also appears inside the empty-feed
    /// `ContentUnavailableView`, so the toolbar button must be found scoped
    /// to the navigation bar to stay unambiguous.
    private func newDiaryEntryToolbarButton(_ app: XCUIApplication) -> XCUIElement {
        app.navigationBars["Circle Diary"].buttons["New Diary Entry"]
    }

    @MainActor
    func testOpeningCircleDiaryShowsTheFeedScreen() throws {
        let app = XCUIApplication()
        openCircleDiary(app)

        XCTAssertTrue(app.navigationBars["Circle Diary"].waitForExistence(timeout: 5))
        XCTAssertTrue(newDiaryEntryToolbarButton(app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testPublishingAPermanentEntryAddsItToTheFeed() throws {
        let app = XCUIApplication()
        openCircleDiary(app)

        newDiaryEntryToolbarButton(app).tap()
        XCTAssertTrue(app.navigationBars["New Diary Entry"].waitForExistence(timeout: 5))

        let bodyText = "Permanent thought \(UUID().uuidString.prefix(8))"
        let textEditor = app.textViews["Diary entry text"]
        XCTAssertTrue(textEditor.waitForExistence(timeout: 5))
        textEditor.tap()
        textEditor.typeText(bodyText)

        app.buttons["Permanent"].tap()

        let publishButton = app.buttons["Publish"]
        XCTAssertTrue(publishButton.isEnabled)
        publishButton.tap()

        XCTAssertTrue(app.navigationBars["Circle Diary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[bodyText].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPublishingATimedEntryShowsItInTheFeedWithAnExpirationLabel() throws {
        let app = XCUIApplication()
        openCircleDiary(app)

        newDiaryEntryToolbarButton(app).tap()
        XCTAssertTrue(app.navigationBars["New Diary Entry"].waitForExistence(timeout: 5))

        let bodyText = "Timed thought \(UUID().uuidString.prefix(8))"
        let textEditor = app.textViews["Diary entry text"]
        XCTAssertTrue(textEditor.waitForExistence(timeout: 5))
        textEditor.tap()
        textEditor.typeText(bodyText)

        // Visibility defaults to "1 day" — leave it timed rather than tapping Permanent.
        let publishButton = app.buttons["Publish"]
        XCTAssertTrue(publishButton.isEnabled)
        publishButton.tap()

        XCTAssertTrue(app.navigationBars["Circle Diary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[bodyText].waitForExistence(timeout: 5))

        let expirationLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Expires in'")).firstMatch
        XCTAssertTrue(expirationLabel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testEmptyTextPreventsPublication() throws {
        let app = XCUIApplication()
        openCircleDiary(app)

        newDiaryEntryToolbarButton(app).tap()
        XCTAssertTrue(app.navigationBars["New Diary Entry"].waitForExistence(timeout: 5))

        let publishButton = app.buttons["Publish"]
        XCTAssertTrue(publishButton.waitForExistence(timeout: 5))
        XCTAssertFalse(publishButton.isEnabled)

        let textEditor = app.textViews["Diary entry text"]
        textEditor.tap()
        textEditor.typeText("   ")
        XCTAssertFalse(publishButton.isEnabled)

        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Circle Diary"].waitForExistence(timeout: 5))
    }
}
