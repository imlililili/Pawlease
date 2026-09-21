import Testing
import Foundation
@testable import Pawlease

struct CoreDataMomentRepositoryTests {
    /// Proves the in-memory Core Data stack can save and fetch a moment, and
    /// that the repository boundary always hands back Sendable `DailyMoment`
    /// domain structs — never `NSManagedObject` instances — to callers.
    @Test func inMemoryStoreCanSaveAndFetchADailyMoment() async throws {
        let persistence = PersistenceController(inMemory: true)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let momentRepo = CoreDataMomentRepository(container: persistence.container)

        let circle = FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        let savedCircle = try await circleRepo.saveCircle(circle)

        let day = CircleDay(value: "2026-03-15")
        let moment = DailyMoment(
            id: UUID(),
            circleID: savedCircle.id,
            authorProfileID: UUID(),
            authorNameSnapshot: "Ava",
            day: day,
            caption: try MomentCaption("Coffee time"),
            moodEmoji: "😀",
            photo: try MomentPhoto(imageData: Data([0xFF, 0xD8]), thumbnailData: Data([0xFF, 0xD8])),
            createdAt: Date()
        )

        let saved: DailyMoment = try await momentRepo.saveMoment(moment)
        let fetched = try await momentRepo.fetchMoments(circleID: savedCircle.id, day: day)

        #expect(fetched.count == 1)
        #expect(fetched.first?.caption.value == "Coffee time")
        #expect(saved.id == moment.id)
    }
}
