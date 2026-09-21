import Testing
import Foundation
@testable import Pawlease

struct LoadPetHomeUseCaseTests {
    @Test func missedDayResetsStreakWithoutDeletingPetGrowthOrMemories() async throws {
        let circleID = UUID()
        let memberID = UUID()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))

        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(
            id: circleID, name: "Test Circle", timezoneIdentifier: "UTC",
            createdAt: clock.now, ownerProfileID: memberID
        )

        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            CircleMember(id: UUID(), circleID: circleID, profileID: memberID, displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)
        ]

        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 42, createdAt: clock.now)

        let momentRepo = InMemoryMomentRepository()
        // Three days ago the Circle survived (two distinct authors). The two
        // days since then were missed, so today's streak should be reset —
        // while the pet's growth and the old memory both remain untouched.
        let threeDaysAgo = CircleDay(date: TestFactories.date(year: 2026, month: 3, day: 12), timeZoneIdentifier: "UTC")
        momentRepo.moments = [
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: threeDaysAgo),
            try TestFactories.moment(circleID: circleID, authorID: UUID(), day: threeDaysAgo)
        ]

        let useCase = LoadPetHomeUseCase(
            circleRepository: circleRepo,
            memberRepository: memberRepo,
            petRepository: petRepo,
            momentRepository: momentRepo,
            clock: clock,
            currentProfileID: memberID
        )

        let snapshot = try await useCase.execute()

        #expect(snapshot.currentStreak == 0)
        #expect(snapshot.pet.growthPoints == 42)
        #expect(momentRepo.moments.count == 2)
    }
}
