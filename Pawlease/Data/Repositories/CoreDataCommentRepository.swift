import CoreData
import Foundation

nonisolated final class CoreDataCommentRepository: CommentRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchComments(momentID: UUID) async throws -> [MomentComment] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = CommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "dailyPost.id == %@", momentID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map(CommentMapper.toDomain)
        }
    }

    func fetchComment(commentID: UUID) async throws -> MomentComment? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = CommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", commentID as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else { return nil }
            return try CommentMapper.toDomain(entity)
        }
    }

    @discardableResult
    func saveComment(_ comment: MomentComment) async throws -> MomentComment {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let postRequest = DailyPostEntity.fetchRequest()
            postRequest.predicate = NSPredicate(format: "id == %@", comment.momentID as CVarArg)
            postRequest.fetchLimit = 1
            guard let postEntity = try context.fetch(postRequest).first else {
                throw DomainError.momentNotFound
            }

            let request = CommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", comment.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? CommentEntity(context: context)
            CommentMapper.apply(comment, to: entity)
            entity.dailyPost = postEntity
            try context.save()
            return try CommentMapper.toDomain(entity)
        }
    }

    func softDeleteComment(commentID: UUID, requestingMemberID: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = CommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", commentID as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else {
                throw DomainError.commentNotFound
            }
            guard entity.authorProfileID == requestingMemberID else {
                throw DomainError.notCommentAuthor
            }
            entity.isRemoved = true
            try context.save()
        }
    }
}
