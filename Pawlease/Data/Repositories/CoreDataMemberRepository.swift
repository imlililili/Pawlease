import CoreData
import Foundation

nonisolated final class CoreDataMemberRepository: MemberRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    /// Fetches every member of a Circle, deterministically ordered
    /// (`joinedAt` ascending, ties broken by `profileID`) and **read-
    /// repaired**: if two or more rows share the same `(circle, profileID)`
    /// pair — e.g. left over from before this repository enforced
    /// uniqueness on save, such as a duplicate created by a since-fixed
    /// concurrent-seeding race — only the earliest-joined row is kept as
    /// canonical and the rest are deleted here, on read. This is what
    /// actually cleans up a store that already has historical duplicates:
    /// `SeedDemoCircleUseCase` never calls `saveMember` again once its
    /// Circle already exists, so the write-side fix in `saveMember` alone
    /// would never reach already-corrupted rows.
    ///
    /// Safe to delete the surplus rows outright: nothing else in the
    /// schema holds a relationship to `MemberEntity` — comments, posts, and
    /// reactions reference `authorProfileID` as a plain scalar, not a
    /// Core Data relationship — so this never touches Circle, pet, posts,
    /// comments, or reactions.
    func fetchMembers(circleID: UUID) async throws -> [CircleMember] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = MemberEntity.fetchRequest()
            request.predicate = NSPredicate(format: "circle.id == %@", circleID as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(key: "joinedAt", ascending: true),
                NSSortDescriptor(key: "profileID", ascending: true)
            ]
            let entities = try context.fetch(request)

            var canonicalByProfileID: [UUID: MemberEntity] = [:]
            var orderedCanonical: [MemberEntity] = []
            var duplicatesToDelete: [MemberEntity] = []

            for entity in entities {
                guard let profileID = entity.profileID else { continue }
                if canonicalByProfileID[profileID] != nil {
                    duplicatesToDelete.append(entity)
                } else {
                    canonicalByProfileID[profileID] = entity
                    orderedCanonical.append(entity)
                }
            }

            if !duplicatesToDelete.isEmpty {
                for duplicate in duplicatesToDelete {
                    context.delete(duplicate)
                }
                try context.save()
            }

            return orderedCanonical.map(MemberMapper.toDomain)
        }
    }

    /// Upserts keyed on `(circle, profileID)` — never on `member.id` alone
    /// — so this enforces at most one Member per profileID within a Circle
    /// at the point of write. This is what stops a *new* duplicate from
    /// ever being created, regardless of what `id` the caller happens to
    /// generate for the `CircleMember` value being saved. Deliberately not
    /// a Core Data unique constraint — this is a plain fetch-then-write
    /// check inside a single `context.perform` block, matching every other
    /// repository in this codebase.
    @discardableResult
    func saveMember(_ member: CircleMember) async throws -> CircleMember {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let circleRequest = CircleEntity.fetchRequest()
            circleRequest.predicate = NSPredicate(format: "id == %@", member.circleID as CVarArg)
            circleRequest.fetchLimit = 1
            guard let circleEntity = try context.fetch(circleRequest).first else {
                throw DomainError.circleNotFound
            }

            let request = MemberEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "circle.id == %@ AND profileID == %@",
                member.circleID as CVarArg, member.profileID as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "joinedAt", ascending: true)]
            let existingMatches = try context.fetch(request)

            let entity: MemberEntity
            if let canonical = existingMatches.first {
                entity = canonical
                // Any additional historical duplicates for this exact
                // (circle, profileID) pair are consolidated away right now
                // too, rather than waiting for the next `fetchMembers`.
                for duplicate in existingMatches.dropFirst() {
                    context.delete(duplicate)
                }
                MemberMapper.applyMutableFields(member, to: entity)
            } else {
                entity = MemberEntity(context: context)
                MemberMapper.apply(member, to: entity)
            }
            entity.circle = circleEntity
            try context.save()
            return MemberMapper.toDomain(entity)
        }
    }
}
