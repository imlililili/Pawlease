import CoreData
import Foundation

nonisolated final class CoreDataPendingPostDraftRepository: PendingPostDraftRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchAll() async throws -> [PendingPostDraft] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PendingPostDraftEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            return try context.fetch(request).map(PendingPostDraftMapper.toDomain)
        }
    }

    func fetchDraft(id: UUID) async throws -> PendingPostDraft? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PendingPostDraftEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else { return nil }
            return try PendingPostDraftMapper.toDomain(entity)
        }
    }

    @discardableResult
    func saveDraft(_ draft: PendingPostDraft) async throws -> PendingPostDraft {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PendingPostDraftEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", draft.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? PendingPostDraftEntity(context: context)
            PendingPostDraftMapper.apply(draft, to: entity)
            try context.save()
            return try PendingPostDraftMapper.toDomain(entity)
        }
    }

    func deleteDraft(id: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = PendingPostDraftEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else { return }
            context.delete(entity)
            try context.save()
        }
    }
}
