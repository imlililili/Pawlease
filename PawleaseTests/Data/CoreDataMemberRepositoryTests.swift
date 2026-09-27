import Testing
import Foundation
import CoreData
@testable import Pawlease

/// Regression coverage for the Circle Settings duplicate-member bug: the
/// repository must enforce at most one `MemberEntity` per `(circleID,
/// profileID)` pair — on write, and by consolidating any pre-existing
/// (historical) duplicates on read — without ever deduplicating by
/// `displayName` and without any Core Data unique constraint.
struct CoreDataMemberRepositoryTests {
    @Test
    func savingTwoMembersWithTheSameCircleAndProfileIDConvergesToOneRow() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let memberRepo = CoreDataMemberRepository(container: persistence.container)

        let circle = try await circleRepo.saveCircle(
            FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        )
        let profileID = UUID()

        // Two different `CircleMember` values (different `id`s) for the
        // same person in the same Circle — exactly what a concurrent-seed
        // or concurrent-membership-completion race used to produce.
        let first = CircleMember(
            id: UUID(), circleID: circle.id, profileID: profileID, displayName: "Ava",
            avatarEmoji: "🐼", joinedAt: Date(timeIntervalSince1970: 1_000), role: .member
        )
        let second = CircleMember(
            id: UUID(), circleID: circle.id, profileID: profileID, displayName: "Ava",
            avatarEmoji: "🐼", joinedAt: Date(timeIntervalSince1970: 2_000), role: .member
        )

        try await memberRepo.saveMember(first)
        try await memberRepo.saveMember(second)

        let members = try await memberRepo.fetchMembers(circleID: circle.id)
        #expect(members.count == 1)
        #expect(members.first?.profileID == profileID)
    }

    @Test
    func fetchMembersConsolidatesPreExistingExactDuplicates() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let memberRepo = CoreDataMemberRepository(container: persistence.container)

        let circle = try await circleRepo.saveCircle(
            FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        )
        let profileID = UUID()

        // Insert two MemberEntity rows directly, bypassing the repository's
        // own upsert guard — simulating a store that already has historical
        // duplicates from before this fix existed. Neither `saveMember`'s
        // write-side guard nor a Core Data unique constraint is what's
        // under test here; `fetchMembers`'s own read-repair is.
        let context = persistence.container.newBackgroundContext()
        try await context.perform {
            let circleRequest = CircleEntity.fetchRequest()
            circleRequest.predicate = NSPredicate(format: "id == %@", circle.id as CVarArg)
            let circleEntity = try context.fetch(circleRequest).first!

            for (offset, name) in ["Ava", "Ava"].enumerated() {
                let entity = MemberEntity(context: context)
                entity.id = UUID()
                entity.profileID = profileID
                entity.displayName = name
                entity.avatarEmoji = "🐼"
                entity.joinedAt = Date(timeIntervalSince1970: Double(1_000 + offset))
                entity.role = CircleMemberRole.member.rawValue
                entity.circle = circleEntity
            }
            try context.save()
        }

        let firstFetch = try await memberRepo.fetchMembers(circleID: circle.id)
        #expect(firstFetch.count == 1)

        // The duplicate row was actually deleted, not just filtered at read
        // time — a second, independent fetch (fresh background context)
        // still sees only one row.
        let secondFetch = try await memberRepo.fetchMembers(circleID: circle.id)
        #expect(secondFetch.count == 1)
        #expect(secondFetch.first?.profileID == profileID)
    }

    @Test
    func distinctPeopleWithTheSameDisplayNameAreBothKept() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let memberRepo = CoreDataMemberRepository(container: persistence.container)

        let circle = try await circleRepo.saveCircle(
            FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        )

        // Two genuinely different people who happen to share a name — must
        // never be collapsed into one, since dedup is keyed on profileID,
        // never on displayName.
        try await memberRepo.saveMember(CircleMember(
            id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "Ava",
            avatarEmoji: "🐼", joinedAt: Date(timeIntervalSince1970: 1_000), role: .member
        ))
        try await memberRepo.saveMember(CircleMember(
            id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "Ava",
            avatarEmoji: "🦉", joinedAt: Date(timeIntervalSince1970: 2_000), role: .member
        ))

        let members = try await memberRepo.fetchMembers(circleID: circle.id)
        #expect(members.count == 2)
        #expect(Set(members.map(\.profileID)).count == 2)
    }

    @Test
    func fetchMembersReturnsDeterministicOrder() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let memberRepo = CoreDataMemberRepository(container: persistence.container)

        let circle = try await circleRepo.saveCircle(
            FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        )
        let later = CircleMember(
            id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "Noah",
            avatarEmoji: "🐨", joinedAt: Date(timeIntervalSince1970: 2_000), role: .member
        )
        let earlier = CircleMember(
            id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "Ava",
            avatarEmoji: "🐼", joinedAt: Date(timeIntervalSince1970: 1_000), role: .member
        )
        try await memberRepo.saveMember(later)
        try await memberRepo.saveMember(earlier)

        let members = try await memberRepo.fetchMembers(circleID: circle.id)
        #expect(members.map(\.displayName) == ["Ava", "Noah"])
    }
}
