import Testing
import Foundation
@testable import Pawlease

/// Mock/in-memory-based only — never touches real Core Data or CloudKit.
struct CompleteJoinedCircleMembershipUseCaseTests {
    private func makeCircle(id: UUID, clock: FakeClock) -> FriendCircle {
        FriendCircle(id: id, name: "Joined Circle", timezoneIdentifier: "UTC", createdAt: clock.now, ownerProfileID: UUID())
    }

    @Test
    func membershipCompletionCreatesOneDistinctMember() async throws {
        let circleID = UUID()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circleRepository = InMemoryCircleRepository()
        circleRepository.circle = makeCircle(id: circleID, clock: clock)
        let memberRepository = InMemoryMemberRepository()
        let profileRepository = InMemoryUserProfileRepository()
        profileRepository.profile = UserProfile(id: UUID(), displayName: "You", avatarEmoji: "🦊", createdAt: clock.now)

        let useCase = CompleteJoinedCircleMembershipUseCase(
            circleRepository: circleRepository, memberRepository: memberRepository,
            userProfileRepository: profileRepository, clock: clock
        )

        let member = try await useCase.execute(handoff: AcceptedCircleHandoff(circleID: circleID))

        #expect(member.circleID == circleID)
        #expect(member.profileID == profileRepository.profile?.id)
        let members = try await memberRepository.fetchMembers(circleID: circleID)
        #expect(members.count == 1)
    }

    @Test
    func repeatedMembershipCompletionDoesNotCreateDuplicates() async throws {
        let circleID = UUID()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circleRepository = InMemoryCircleRepository()
        circleRepository.circle = makeCircle(id: circleID, clock: clock)
        let memberRepository = InMemoryMemberRepository()
        let profileRepository = InMemoryUserProfileRepository()
        profileRepository.profile = UserProfile(id: UUID(), displayName: "You", avatarEmoji: "🦊", createdAt: clock.now)

        let useCase = CompleteJoinedCircleMembershipUseCase(
            circleRepository: circleRepository, memberRepository: memberRepository,
            userProfileRepository: profileRepository, clock: clock
        )

        let first = try await useCase.execute(handoff: AcceptedCircleHandoff(circleID: circleID))
        let second = try await useCase.execute(handoff: AcceptedCircleHandoff(circleID: circleID))

        #expect(first.id == second.id)
        let members = try await memberRepository.fetchMembers(circleID: circleID)
        #expect(members.count == 1)
    }

    @Test
    func seededPlaceholderMembersAreNotMistakenForTheCurrentUser() async throws {
        let circleID = UUID()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circleRepository = InMemoryCircleRepository()
        circleRepository.circle = makeCircle(id: circleID, clock: clock)
        let memberRepository = InMemoryMemberRepository()
        // Two placeholder members already exist, neither matching the
        // current profile ID.
        memberRepository.members = [
            TestFactories.member(circleID: circleID, profileID: UUID(), displayName: "Ava"),
            TestFactories.member(circleID: circleID, profileID: UUID(), displayName: "Noah")
        ]
        let profileRepository = InMemoryUserProfileRepository()
        profileRepository.profile = UserProfile(id: UUID(), displayName: "You", avatarEmoji: "🦊", createdAt: clock.now)

        let useCase = CompleteJoinedCircleMembershipUseCase(
            circleRepository: circleRepository, memberRepository: memberRepository,
            userProfileRepository: profileRepository, clock: clock
        )

        let member = try await useCase.execute(handoff: AcceptedCircleHandoff(circleID: circleID))

        #expect(member.profileID == profileRepository.profile?.id)
        let members = try await memberRepository.fetchMembers(circleID: circleID)
        #expect(members.count == 3)
    }

    @Test
    func aSixthMemberIsRejected() async {
        let circleID = UUID()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circleRepository = InMemoryCircleRepository()
        circleRepository.circle = makeCircle(id: circleID, clock: clock)
        let memberRepository = InMemoryMemberRepository()
        memberRepository.members = (0..<5).map { _ in TestFactories.member(circleID: circleID, profileID: UUID()) }
        let profileRepository = InMemoryUserProfileRepository()
        profileRepository.profile = UserProfile(id: UUID(), displayName: "You", avatarEmoji: "🦊", createdAt: clock.now)

        let useCase = CompleteJoinedCircleMembershipUseCase(
            circleRepository: circleRepository, memberRepository: memberRepository,
            userProfileRepository: profileRepository, clock: clock
        )

        await #expect(throws: DomainError.membershipFull) {
            _ = try await useCase.execute(handoff: AcceptedCircleHandoff(circleID: circleID))
        }
        let members = try? await memberRepository.fetchMembers(circleID: circleID)
        #expect(members?.count == 5)
    }

    @Test
    func anUnresolvedHandoffIsNeverGuessed() async {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circleRepository = InMemoryCircleRepository()
        circleRepository.circle = makeCircle(id: UUID(), clock: clock) // a different, unrelated Circle
        let memberRepository = InMemoryMemberRepository()
        let profileRepository = InMemoryUserProfileRepository()

        let useCase = CompleteJoinedCircleMembershipUseCase(
            circleRepository: circleRepository, memberRepository: memberRepository,
            userProfileRepository: profileRepository, clock: clock
        )

        await #expect(throws: DomainError.circleNotFound) {
            _ = try await useCase.execute(handoff: AcceptedCircleHandoff(circleID: nil))
        }
        #expect(profileRepository.fetchOrCreateCallCount == 0)
    }
}
