import CoreData
import Foundation

nonisolated final class CoreDataDiaryReactionRepository: DiaryReactionRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchReactions(entryID: UUID) async throws -> [DiaryReaction] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DiaryReactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "diaryEntry.id == %@", entryID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map(DiaryReactionMapper.toDomain)
        }
    }

    func reaction(entryID: UUID, memberProfileID: UUID) async throws -> DiaryReaction? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            guard let entity = try Self.fetchReactionEntity(entryID: entryID, memberProfileID: memberProfileID, context: context) else {
                return nil
            }
            return try DiaryReactionMapper.toDomain(entity)
        }
    }

    func saveReaction(_ reaction: DiaryReaction) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let entryRequest = DiaryEntryEntity.fetchRequest()
            entryRequest.predicate = NSPredicate(format: "id == %@", reaction.entryID as CVarArg)
            entryRequest.fetchLimit = 1
            guard let entryEntity = try context.fetch(entryRequest).first else {
                throw DomainError.diaryEntryNotFound
            }

            // Enforce one reaction per member per entry: upsert on the
            // existing (entry, member) row rather than appending a new one.
            let entity = try Self.fetchReactionEntity(
                entryID: reaction.entryID, memberProfileID: reaction.memberProfileID, context: context
            ) ?? DiaryReactionEntity(context: context)
            DiaryReactionMapper.apply(reaction, to: entity)
            entity.diaryEntry = entryEntity
            try context.save()
        }
    }

    func removeReaction(entryID: UUID, memberProfileID: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = DiaryReactionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "diaryEntry.id == %@ AND authorProfileID == %@",
                entryID as CVarArg, memberProfileID as CVarArg
            )
            for entity in try context.fetch(request) {
                context.delete(entity)
            }
            try context.save()
        }
    }

    private static func fetchReactionEntity(
        entryID: UUID, memberProfileID: UUID, context: NSManagedObjectContext
    ) throws -> DiaryReactionEntity? {
        let request = DiaryReactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "diaryEntry.id == %@ AND authorProfileID == %@",
            entryID as CVarArg, memberProfileID as CVarArg
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
