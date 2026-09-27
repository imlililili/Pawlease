import Testing
import Foundation
@testable import Pawlease

/// Regression coverage for `CleanUpLegacyDemoFriendUseCase`: this must be
/// airtight-narrow — it may only ever touch the one exact, hardcoded legacy
/// profile ID, never a display name, never any other member or Circle.
/// Mock/in-memory-based only — never touches real Core Data or CloudKit.
struct CleanUpLegacyDemoFriendUseCaseTests {
    private func makeUseCase(memberRepository: MemberRepository, momentRepository: MomentRepository) -> CleanUpLegacyDemoFriendUseCase {
        CleanUpLegacyDemoFriendUseCase(memberRepository: memberRepository, momentRepository: momentRepository)
    }

    @Test
    func removesTheLegacyAvaMemberAndHerPosts() async throws {
        let circleID = UUID()
        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let legacyID = CleanUpLegacyDemoFriendUseCase.legacyAvaProfileID

        memberRepo.members = [
            CircleMember(id: UUID(), circleID: circleID, profileID: legacyID, displayName: "Ava", avatarEmoji: "🌼", joinedAt: Date(), role: .member)
        ]
        momentRepo.moments = [try TestFactories.moment(circleID: circleID, authorID: legacyID, day: CircleDay(value: "2026-03-15"))]

        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo)
        try await useCase.execute(circleID: circleID)

        #expect(memberRepo.members.isEmpty)
        #expect(momentRepo.moments.isEmpty)
    }

    /// A genuinely different person could legitimately be named "Ava" too
    /// — this cleanup must never use display name as a signal, only the
    /// one exact legacy profile ID.
    @Test
    func sameNameMembersWithGenuinelyDifferentProfileIDsArePreserved() async throws {
        let circleID = UUID()
        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()

        let seededAvaID = DemoSeed.avaProfileID
        let realAvaID = UUID() // a genuinely different person who also happens to be named "Ava"
        memberRepo.members = [
            CircleMember(id: UUID(), circleID: circleID, profileID: seededAvaID, displayName: "Ava", avatarEmoji: "🐼", joinedAt: Date(), role: .member),
            CircleMember(id: UUID(), circleID: circleID, profileID: realAvaID, displayName: "Ava", avatarEmoji: "🌸", joinedAt: Date(), role: .member)
        ]

        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo)
        try await useCase.execute(circleID: circleID)

        // Neither "Ava" was touched — matching is by profile ID only, and
        // neither of these profile IDs is the legacy one.
        #expect(memberRepo.members.count == 2)
        #expect(memberRepo.members.contains { $0.profileID == seededAvaID })
        #expect(memberRepo.members.contains { $0.profileID == realAvaID })
    }

    @Test
    func cannotAffectUnknownProfiles() async throws {
        let circleID = UUID()
        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()

        // No member or moment anywhere uses the legacy profile ID — every
        // profile ID here is "unknown" to this cleanup.
        let unrelatedMembers = (0..<3).map { _ in TestFactories.member(circleID: circleID, profileID: UUID()) }
        memberRepo.members = unrelatedMembers
        momentRepo.moments = try unrelatedMembers.map {
            try TestFactories.moment(circleID: circleID, authorID: $0.profileID, day: CircleDay(value: "2026-03-15"))
        }

        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo)
        try await useCase.execute(circleID: circleID)

        #expect(memberRepo.members.count == 3)
        #expect(momentRepo.moments.count == 3)
        #expect(Set(memberRepo.members.map(\.profileID)) == Set(unrelatedMembers.map(\.profileID)))
    }

    @Test
    func onlyAffectsTheGivenCircle() async throws {
        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let legacyID = CleanUpLegacyDemoFriendUseCase.legacyAvaProfileID
        let targetCircleID = UUID()
        let otherCircleID = UUID()

        memberRepo.members = [
            CircleMember(id: UUID(), circleID: otherCircleID, profileID: legacyID, displayName: "Ava", avatarEmoji: "🌼", joinedAt: Date(), role: .member)
        ]

        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo)
        try await useCase.execute(circleID: targetCircleID)

        // A member with the legacy profile ID in a different Circle is
        // left alone — the cleanup is scoped per Circle.
        #expect(memberRepo.members.count == 1)
    }
}
