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
        XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 15))
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

    /// Publishes one entry and taps its feed row into `DiaryEntryDetailView`.
    /// Returns the app positioned there, with the entry's `bodyText`, for
    /// shared setup across the navigation/reaction regression tests below.
    private func publishEntryAndOpenDetail(_ app: XCUIApplication) -> String {
        openCircleDiary(app)

        newDiaryEntryToolbarButton(app).tap()
        let bodyText = "Navigation test \(UUID().uuidString.prefix(8))"
        let textEditor = app.textViews["Diary entry text"]
        XCTAssertTrue(textEditor.waitForExistence(timeout: 5))
        textEditor.tap()
        textEditor.typeText(bodyText)
        app.buttons["Publish"].tap()

        let entryLink = app.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", bodyText))
            .firstMatch
        XCTAssertTrue(entryLink.waitForExistence(timeout: 5))
        entryLink.tap()
        return bodyText
    }

    /// Regression items 1-4 for Bug 2: tapping a feed row opens exactly one
    /// Diary Entry detail screen, navigation depth does not keep growing on
    /// its own, the user can remain on the screen, and the comment composer
    /// stays interactive throughout.
    @MainActor
    func testDiaryEntryDetailOpensOnceStaysOpenAndKeepsTheComposerInteractive() throws {
        let app = XCUIApplication()
        _ = publishEntryAndOpenDetail(app)

        // Exactly one Diary Entry screen — not stacked/pushed repeatedly.
        XCTAssertTrue(app.navigationBars["Diary Entry"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.navigationBars.matching(identifier: "Diary Entry").count, 1)

        // The app must actually stay here — before the fix, an ancestor
        // re-render (e.g. a remote-change-driven `refresh()` on Pet Home)
        // could reconstruct the pushed screen's identity and destabilize
        // the stack out from under the user.
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(app.navigationBars["Diary Entry"].exists)
        XCTAssertEqual(app.navigationBars.matching(identifier: "Diary Entry").count, 1)

        // The comment composer (shared `CommentComposer` component,
        // `accessibilityLabel("Comment")`) must stay interactive.
        let commentField = app.textFields["Comment"]
        XCTAssertTrue(commentField.waitForExistence(timeout: 5))
        XCTAssertTrue(commentField.isEnabled)
        commentField.tap()
        commentField.typeText("Nice entry!")
        XCTAssertEqual(commentField.value as? String, "Nice entry!")
    }

    /// Regression item 5 for Bug 1: React must be a real button, and
    /// selecting it must never reveal a separately-visible, independently
    /// typeable text field. Does not attempt to pick an emoji from the
    /// actual system keyboard — XCUITest cannot reliably automate that
    /// against Apple's own keyboard (no stable per-key identifiers, and
    /// simulator emoji-keyboard automation is notoriously flaky); see the
    /// completion report for the exact manual procedure that covers
    /// selecting/replacing/removing a real reaction end to end.
    @MainActor
    func testReactionButtonOpensInputWithoutRevealingAVisibleTextField() throws {
        let app = XCUIApplication()
        _ = publishEntryAndOpenDetail(app)
        XCTAssertTrue(app.navigationBars["Diary Entry"].waitForExistence(timeout: 5))

        let reactButton = app.buttons["React with an emoji"]
        XCTAssertTrue(reactButton.waitForExistence(timeout: 5))
        // Baseline includes the screen's own comment composer `TextField`
        // ("Comment") — a legitimate, always-visible field. What matters is
        // that selecting React never adds a NEW one.
        let textFieldCountBeforeReact = app.textFields.count

        reactButton.tap()
        // TEMP PROBE
        XCTContext.runActivity(named: "PROBE textFields=\(app.textFields.allElementsBoundByIndex.map { "[\($0.label)|\($0.value ?? "nil")]" })") { _ in }
        XCTAssertEqual(
            app.textFields.count, textFieldCountBeforeReact,
            "Selecting React must never expose a new visible/accessible text field"
        )
    }

    /// Regression for Bug 2: opening Circle Diary, leaving it, and opening
    /// it again repeatedly must keep working identically each time — before
    /// the fix, a fresh `CircleDiaryFeedViewModel` (and thus a freshly
    /// re-registered `.navigationDestination`) on every `PetHomeView`
    /// re-render made the stack's bookkeeping progressively unstable.
    @MainActor
    func testCircleDiaryNavigationIsStableAcrossRepeatedOpens() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 15))

        for _ in 0..<3 {
            app.buttons["Circle Diary"].tap()
            XCTAssertTrue(app.navigationBars["Circle Diary"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.navigationBars.matching(identifier: "Circle Diary").count, 1)
            app.navigationBars["Circle Diary"].buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.navigationBars["Pet Home"].waitForExistence(timeout: 5))
        }
    }

    /// Covers "Feed and Archive navigation both work" — Archive is
    /// presented in its own sheet-local `NavigationStack`, independent from
    /// the Feed's, and must open/dismiss cleanly.
    @MainActor
    func testArchiveOpensAndReturnsToFeed() throws {
        let app = XCUIApplication()
        openCircleDiary(app)

        // `.secondaryAction` toolbar items collapse into the overflow
        // "More" menu rather than appearing directly on the navigation bar.
        app.navigationBars["Circle Diary"].buttons["OverflowBarButtonItem"].tap()
        app.buttons["My Archive"].tap()
        XCTAssertTrue(app.navigationBars["My Diary Archive"].waitForExistence(timeout: 5))

        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Circle Diary"].waitForExistence(timeout: 5))
    }
}
