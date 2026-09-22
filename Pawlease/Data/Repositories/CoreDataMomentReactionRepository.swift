import CoreData
import Foundation

nonisolated final class CoreDataMomentReactionRepository: MomentReactionRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchReactions(momentID: UUID) async throws -> [MomentReaction] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PostReactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "dailyPost.id == %@", momentID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map(MomentReactionMapper.toDomain)
        }
    }

    func reaction(momentID: UUID, memberProfileID: UUID) async throws -> MomentReaction? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            guard let entity = try Self.fetchReactionEntity(momentID: momentID, memberProfileID: memberProfileID, context: context) else {
                return nil
            }
            return try MomentReactionMapper.toDomain(entity)
        }
    }

    func saveReaction(_ reaction: MomentReaction) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let postRequest = DailyPostEntity.fetchRequest()
            postRequest.predicate = NSPredicate(format: "id == %@", reaction.momentID as CVarArg)
            postRequest.fetchLimit = 1
            guard let postEntity = try context.fetch(postRequest).first else {
                throw DomainError.momentNotFound
            }

            // Enforce one reaction per member per moment: upsert on the
            // existing (moment, member) row rather than appending a new one.
            let entity = try Self.fetchReactionEntity(
                momentID: reaction.momentID, memberProfileID: reaction.memberProfileID, context: context
            ) ?? PostReactionEntity(context: context)
            MomentReactionMapper.apply(reaction, to: entity)
            entity.dailyPost = postEntity
            try context.save()
        }
    }

    func removeReaction(momentID: UUID, memberProfileID: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = PostReactionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "dailyPost.id == %@ AND authorProfileID == %@",
                momentID as CVarArg, memberProfileID as CVarArg
            )
            for entity in try context.fetch(request) {
                context.delete(entity)
            }
            try context.save()
        }
    }

    private static func fetchReactionEntity(
        momentID: UUID, memberProfileID: UUID, context: NSManagedObjectContext
    ) throws -> PostReactionEntity? {
        let request = PostReactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "dailyPost.id == %@ AND authorProfileID == %@",
            momentID as CVarArg, memberProfileID as CVarArg
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
