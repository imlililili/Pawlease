import Testing
import Foundation
@testable import Pawlease

struct WidgetSnapshotTests {
    @Test
    func widgetSnapshotEncodesAndDecodesWithoutLoss() throws {
        let original = WidgetSnapshot(
            circleID: UUID(),
            petName: "Mochi",
            petSpeciesKey: "fox",
            currentStreak: 7,
            contributorCount: 2,
            requiredContributorCount: 2,
            hasSurvivedToday: true,
            hasCurrentMemberPostedToday: true,
            circleDayKey: "2026-03-15",
            lastUpdated: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func placeholderSnapshotHasNoSurvivedContributionsYet() {
        let placeholder = WidgetSnapshot.placeholder

        #expect(placeholder.contributorCount == 0)
        #expect(placeholder.hasSurvivedToday == false)
        #expect(placeholder.hasCurrentMemberPostedToday == false)
    }
}
