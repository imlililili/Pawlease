import Foundation
import Testing
@testable import Pawlease

struct DiaryVisibilityDurationTests {
    private let createdAt = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func oneDayEntryRemainsActiveImmediatelyBefore24Hours() throws {
        let entry = try makeEntry(duration: .oneDay)
        let justBefore = createdAt.addingTimeInterval(24 * 3600 - 1)
        #expect(entry.isExpired(asOf: justBefore) == false)
        #expect(entry.isActive(asOf: justBefore) == true)
    }

    @Test
    func oneDayEntryExpiresExactlyAt24Hours() throws {
        let entry = try makeEntry(duration: .oneDay)
        let exactly24Hours = createdAt.addingTimeInterval(24 * 3600)
        #expect(entry.isExpired(asOf: exactly24Hours) == true)
        #expect(entry.isActive(asOf: exactly24Hours) == false)
    }

    @Test
    func threeDayAndSevenDayExpiryCalculationsAreCorrect() {
        let threeDayExpiry = DiaryVisibilityDuration.threeDays.expiresAt(from: createdAt)
        #expect(threeDayExpiry == createdAt.addingTimeInterval(72 * 3600))

        let sevenDayExpiry = DiaryVisibilityDuration.sevenDays.expiresAt(from: createdAt)
        #expect(sevenDayExpiry == createdAt.addingTimeInterval(168 * 3600))
    }

    @Test
    func permanentEntryNeverExpires() throws {
        let entry = try makeEntry(duration: .permanent)
        #expect(entry.expiresAt == nil)
        let farFuture = createdAt.addingTimeInterval(365 * 24 * 3600)
        #expect(entry.isExpired(asOf: farFuture) == false)
        #expect(entry.isActive(asOf: farFuture) == true)
    }

    private func makeEntry(duration: DiaryVisibilityDuration) throws -> DiaryEntry {
        DiaryEntry(
            id: UUID(), circleID: UUID(), authorProfileID: UUID(),
            authorNameSnapshot: "Ada", authorAvatarSnapshot: "🐾",
            body: try DiaryEntryBody("hello"), visibilityDuration: duration,
            createdAt: createdAt, expiresAt: duration.expiresAt(from: createdAt),
            isDeleted: false, deletedAt: nil
        )
    }
}
