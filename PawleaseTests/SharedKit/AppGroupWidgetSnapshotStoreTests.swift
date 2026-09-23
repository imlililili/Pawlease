import Testing
import Foundation
@testable import Pawlease

/// Exercises the real `AppGroupWidgetSnapshotStore` against a throwaway
/// `UserDefaults` suite (never the real `group.com.lili.Pawlease` App
/// Group), so these tests need no App Group entitlement, Core Data, or
/// CloudKit — just local `UserDefaults`, cleaned up after each test.
struct AppGroupWidgetSnapshotStoreTests {
    @Test
    func savedSnapshotIsReadBackIdentically() throws {
        let suiteName = "test.pawlease.widget.\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suiteName) }
        let store = AppGroupWidgetSnapshotStore(appGroupIdentifier: suiteName)

        let snapshot = WidgetSnapshot(
            circleID: UUID(),
            petName: "Mochi",
            petSpeciesKey: "fox",
            currentStreak: 2,
            contributorCount: 2,
            requiredContributorCount: 2,
            hasSurvivedToday: true,
            hasCurrentMemberPostedToday: true,
            circleDayKey: "2026-03-15",
            lastUpdated: Date(timeIntervalSince1970: 1_800_000_000)
        )

        try store.save(snapshot)

        #expect(store.loadSnapshot() == snapshot)
    }

    @Test
    func missingSharedDataFallsBackToThePlaceholderSnapshot() {
        let suiteName = "test.pawlease.widget.\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suiteName) }
        let store = AppGroupWidgetSnapshotStore(appGroupIdentifier: suiteName)

        // Nothing has ever been saved to this suite.
        #expect(store.loadSnapshot() == .placeholder)
    }
}
