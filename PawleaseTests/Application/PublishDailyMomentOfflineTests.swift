import Testing
import Foundation
@testable import Pawlease

struct PublishDailyMomentOfflineTests {
    /// `PublishDailyMomentUseCase` never touches `CloudAccountStatusProviding`
    /// or `CircleSharingRepository` — publishing is local-first and
    /// optimistic. This proves a moment stays visible through the
    /// repository regardless of iCloud/network availability, without
    /// needing a fake network layer at all: there simply isn't one in the
    /// publish path.
    @Test
    func unavailableNetworkKeepsLocallyPublishedMomentVisible() async throws {
        let momentRepository = InMemoryMomentRepository()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = PublishDailyMomentUseCase(momentRepository: momentRepository, clock: clock)

        let circle = FriendCircle(id: UUID(), name: "Test", timezoneIdentifier: "UTC", createdAt: clock.now, ownerProfileID: UUID())
        let member = TestFactories.member(circleID: circle.id)
        let photo = try MomentPhoto(imageData: Data([0xFF]), thumbnailData: Data([0xFF]))

        let published = try await useCase.execute(
            circle: circle, member: member, photo: photo, captionText: "Offline post", moodEmoji: nil
        )

        let day = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        let fetched = try await momentRepository.fetchMoments(circleID: circle.id, day: day)

        #expect(fetched.count == 1)
        #expect(fetched.first?.id == published.id)
        #expect(fetched.first?.caption.value == "Offline post")
    }
}
