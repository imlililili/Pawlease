import CoreData
import Foundation

nonisolated final class CoreDataCommentReactionRepository: CommentReactionRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchReactions(commentID: UUID) async throws -> [CommentReaction] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = CommentReactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "comment.id == %@", commentID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map(CommentReactionMapper.toDomain)
        }
    }

    func reaction(commentID: UUID, memberProfileID: UUID) async throws -> CommentReaction? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            guard let entity = try Self.fetchReactionEntity(commentID: commentID, memberProfileID: memberProfileID, context: context) else {
                return nil
            }
            return try CommentReactionMapper.toDomain(entity)
        }
    }

    func saveReaction(_ reaction: CommentReaction) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let commentRequest = CommentEntity.fetchRequest()
            commentRequest.predicate = NSPredicate(format: "id == %@", reaction.commentID as CVarArg)
            commentRequest.fetchLimit = 1
            guard let commentEntity = try context.fetch(commentRequest).first else {
                throw DomainError.commentNotFound
            }

            // Enforce one reaction per member per comment: upsert on the
            // existing (comment, member) row rather than appending a new one.
            let entity = try Self.fetchReactionEntity(
                commentID: reaction.commentID, memberProfileID: reaction.memberProfileID, context: context
            ) ?? CommentReactionEntity(context: context)
            CommentReactionMapper.apply(reaction, to: entity)
            entity.comment = commentEntity
            try context.save()
        }
    }

    func removeReaction(commentID: UUID, memberProfileID: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = CommentReactionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "comment.id == %@ AND authorProfileID == %@",
                commentID as CVarArg, memberProfileID as CVarArg
            )
            for entity in try context.fetch(request) {
                context.delete(entity)
            }
            try context.save()
        }
    }

    private static func fetchReactionEntity(
        commentID: UUID, memberProfileID: UUID, context: NSManagedObjectContext
    ) throws -> CommentReactionEntity? {
        let request = CommentReactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "comment.id == %@ AND authorProfileID == %@",
            commentID as CVarArg, memberProfileID as CVarArg
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
