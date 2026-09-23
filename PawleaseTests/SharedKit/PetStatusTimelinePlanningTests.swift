import Testing
import Foundation
@testable import Pawlease

/// Tests the pure logic behind the Pet Status widget's `TimelineProvider`
/// (`PetStatusTimelinePlanning` + `PetStatusDisplay`), which is kept
/// framework-independent in `SharedKit` specifically so it's reachable here
/// via `@testable import Pawlease` — the actual `TimelineProvider`
/// conformance lives in the Widget extension target and can't be. No real
/// Core Data or CloudKit is involved; the store dependency is a mock.
struct PetStatusTimelinePlanningTests {
    @Test
    func savedSnapshotBecomesTheTimelineEntry() {
        let store = MockWidgetSnapshotStore()
        let saved = WidgetSnapshot(
            circleID: UUID(),
            petName: "Mochi",
            petSpeciesKey: "fox",
            currentStreak: 5,
            contributorCount: 2,
            requiredContributorCount: 2,
            hasSurvivedToday: true,
            hasCurrentMemberPostedToday: true,
            circleDayKey: "2026-09-23",
            lastUpdated: Date(timeIntervalSince1970: 1_800_000_000)
        )
        store.stubbedLoadSnapshot = saved

        let display = PetStatusTimelinePlanning.makeDisplay(from: store, at: Date(timeIntervalSince1970: 1_800_000_100))

        #expect(display.snapshot == saved)
        #expect(display.isPlaceholder == false)
        #expect(store.loadSnapshotCallCount == 1)
    }

    @Test
    func missingSharedDataProducesTheFallbackEntry() {
        let store = MockWidgetSnapshotStore()
        store.stubbedLoadSnapshot = .placeholder

        let display = PetStatusTimelinePlanning.makeDisplay(from: store, at: Date())

        #expect(display.snapshot == .placeholder)
        #expect(display.isPlaceholder == true)
        #expect(display.status == .noSharedData)
    }

    @Test
    func survivedDayMapsToTheSurvivedDisplayStatus() {
        let snapshot = WidgetSnapshot(
            circleID: UUID(), petName: "Mochi", petSpeciesKey: "fox", currentStreak: 3,
            contributorCount: 2, requiredContributorCount: 2, hasSurvivedToday: true,
            hasCurrentMemberPostedToday: true, circleDayKey: "2026-09-23", lastUpdated: Date()
        )

        let display = PetStatusDisplay(date: Date(), snapshot: snapshot, isPlaceholder: false)

        #expect(display.status == .survivedToday)
    }

    @Test
    func waitingForAnotherContributorMapsToTheWaitingDisplayStatus() {
        // Current member already posted; the Circle still needs one more
        // distinct contributor today.
        let snapshot = WidgetSnapshot(
            circleID: UUID(), petName: "Mochi", petSpeciesKey: "fox", currentStreak: 3,
            contributorCount: 1, requiredContributorCount: 2, hasSurvivedToday: false,
            hasCurrentMemberPostedToday: true, circleDayKey: "2026-09-23", lastUpdated: Date()
        )

        let display = PetStatusDisplay(date: Date(), snapshot: snapshot, isPlaceholder: false)

        #expect(display.status == .waitingForAnotherFriend)
    }

    @Test
    func unpostedCurrentMemberMapsToTheNeedsToPostDisplayStatus() {
        let snapshot = WidgetSnapshot(
            circleID: UUID(), petName: "Mochi", petSpeciesKey: "fox", currentStreak: 3,
            contributorCount: 0, requiredContributorCount: 2, hasSurvivedToday: false,
            hasCurrentMemberPostedToday: false, circleDayKey: "2026-09-23", lastUpdated: Date()
        )

        let display = PetStatusDisplay(date: Date(), snapshot: snapshot, isPlaceholder: false)

        #expect(display.status == .needsCurrentMemberToPost)
    }

    @Test
    func theNextRefreshDateAlwaysFollowsTheEntryDate() {
        let entryDate = Date()

        let refreshDate = PetStatusTimelinePlanning.nextRefreshDate(after: entryDate)

        #expect(refreshDate > entryDate)
    }

    @Test
    func theNextRefreshDateNeverExceedsOneHourEvenAcrossADayBoundary() {
        // 23:50 local time: the next-midnight boundary is only 10 minutes
        // away, well inside the one-hour ceiling.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let entryDate = calendar.date(from: DateComponents(year: 2026, month: 9, day: 23, hour: 23, minute: 50))!

        let refreshDate = PetStatusTimelinePlanning.nextRefreshDate(after: entryDate, calendar: calendar)

        #expect(refreshDate > entryDate)
        #expect(refreshDate.timeIntervalSince(entryDate) <= 60 * 60)
    }
}
