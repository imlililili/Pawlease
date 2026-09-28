import CoreData
import Foundation

nonisolated final class CoreDataDiaryCommentReactionRepository: DiaryCommentReactionRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchReactions(commentID: UUID) async throws -> [DiaryCommentReaction] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DiaryCommentReactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "diaryComment.id == %@", commentID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map(DiaryCommentReactionMapper.toDomain)
        }
    }

    func reaction(commentID: UUID, memberProfileID: UUID) async throws -> DiaryCommentReaction? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            guard let entity = try Self.fetchReactionEntity(commentID: commentID, memberProfileID: memberProfileID, context: context) else {
                return nil
            }
            return try DiaryCommentReactionMapper.toDomain(entity)
        }
    }

    func saveReaction(_ reaction: DiaryCommentReaction) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let commentRequest = DiaryCommentEntity.fetchRequest()
            commentRequest.predicate = NSPredicate(format: "id == %@", reaction.commentID as CVarArg)
            commentRequest.fetchLimit = 1
            guard let commentEntity = try context.fetch(commentRequest).first else {
                throw DomainError.diaryCommentNotFound
            }

            let entity = try Self.fetchReactionEntity(
                commentID: reaction.commentID, memberProfileID: reaction.memberProfileID, context: context
            ) ?? DiaryCommentReactionEntity(context: context)
            DiaryCommentReactionMapper.apply(reaction, to: entity)
            entity.diaryComment = commentEntity
            try context.save()
        }
    }

    func removeReaction(commentID: UUID, memberProfileID: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = DiaryCommentReactionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "diaryComment.id == %@ AND authorProfileID == %@",
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
    ) throws -> DiaryCommentReactionEntity? {
        let request = DiaryCommentReactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "diaryComment.id == %@ AND authorProfileID == %@",
            commentID as CVarArg, memberProfileID as CVarArg
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
