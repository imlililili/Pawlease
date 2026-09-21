import Testing
import Foundation
@testable import Pawlease

struct PublishDailyMomentUseCaseTests {
    /// Documented policy: a second contribution from the same member on the
    /// same Circle day replaces the first rather than creating a duplicate.
    @Test func duplicateContributionsFromOneMemberReplaceThePreviousPost() async throws {
        let momentRepo = InMemoryMomentRepository()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = PublishDailyMomentUseCase(momentRepository: momentRepo, clock: clock)

        let circle = FriendCircle(id: UUID(), name: "Test", timezoneIdentifier: "UTC", createdAt: clock.now, ownerProfileID: UUID())
        let member = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)
        let photo = try MomentPhoto(imageData: Data([0xFF]), thumbnailData: Data([0xFF]))

        _ = try await useCase.execute(circle: circle, member: member, photo: photo, captionText: "First try", moodEmoji: nil)
        let second = try await useCase.execute(circle: circle, member: member, photo: photo, captionText: "Second try", moodEmoji: "😀")

        let day = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        let momentsToday = try await momentRepo.fetchMoments(circleID: circle.id, day: day)

        #expect(momentsToday.count == 1)
        #expect(momentsToday.first?.caption.value == "Second try")
        #expect(second.caption.value == "Second try")
    }
}
