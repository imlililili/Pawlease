import CoreData
import Foundation

nonisolated final class CoreDataDiaryCommentRepository: DiaryCommentRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchComments(entryID: UUID) async throws -> [DiaryComment] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DiaryCommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "diaryEntry.id == %@", entryID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map(DiaryCommentMapper.toDomain)
        }
    }

    func fetchComment(commentID: UUID) async throws -> DiaryComment? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DiaryCommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", commentID as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else { return nil }
            return try DiaryCommentMapper.toDomain(entity)
        }
    }

    @discardableResult
    func saveComment(_ comment: DiaryComment) async throws -> DiaryComment {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let entryRequest = DiaryEntryEntity.fetchRequest()
            entryRequest.predicate = NSPredicate(format: "id == %@", comment.entryID as CVarArg)
            entryRequest.fetchLimit = 1
            guard let entryEntity = try context.fetch(entryRequest).first else {
                throw DomainError.diaryEntryNotFound
            }

            let request = DiaryCommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", comment.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? DiaryCommentEntity(context: context)
            DiaryCommentMapper.apply(comment, to: entity)
            entity.diaryEntry = entryEntity
            try context.save()
            return try DiaryCommentMapper.toDomain(entity)
        }
    }

    func softDeleteComment(commentID: UUID, requestingMemberID: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = DiaryCommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", commentID as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else {
                throw DomainError.diaryCommentNotFound
            }
            guard entity.authorProfileID == requestingMemberID else {
                throw DomainError.notCommentAuthor
            }
            entity.isRemoved = true
            try context.save()
        }
    }
}
