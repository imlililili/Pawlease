import Foundation

/// Preview-only fixture data, shared by the small and medium view previews.
/// Never used by the real `PetStatusProvider` — that always goes through
/// `WidgetSnapshotStoring`.
extension PetStatusDisplay {
    static func preview(survived: Bool) -> PetStatusDisplay {
        let snapshot = WidgetSnapshot(
            circleID: UUID(),
            petName: "Mochi",
            petSpeciesKey: "fox",
            currentStreak: 4,
            contributorCount: survived ? 2 : 1,
            requiredContributorCount: 2,
            hasSurvivedToday: survived,
            hasCurrentMemberPostedToday: true,
            circleDayKey: "2026-09-23",
            lastUpdated: Date()
        )
        return PetStatusDisplay(date: Date(), snapshot: snapshot, isPlaceholder: false)
    }
}
