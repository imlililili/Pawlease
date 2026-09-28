import CoreData
import Foundation

nonisolated final class CoreDataDiaryEntryRepository: DiaryEntryRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchEntries(circleID: UUID) async throws -> [DiaryEntry] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DiaryEntryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "circle.id == %@", circleID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            return try context.fetch(request).map(DiaryEntryMapper.toDomain)
        }
    }

    func fetchEntry(entryID: UUID) async throws -> DiaryEntry? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DiaryEntryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entryID as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else { return nil }
            return try DiaryEntryMapper.toDomain(entity)
        }
    }

    @discardableResult
    func saveEntry(_ entry: DiaryEntry) async throws -> DiaryEntry {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let circleRequest = CircleEntity.fetchRequest()
            circleRequest.predicate = NSPredicate(format: "id == %@", entry.circleID as CVarArg)
            circleRequest.fetchLimit = 1
            guard let circleEntity = try context.fetch(circleRequest).first else {
                throw DomainError.circleNotFound
            }

            let request = DiaryEntryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? DiaryEntryEntity(context: context)
            DiaryEntryMapper.apply(entry, to: entity)
            entity.circle = circleEntity
            try context.save()
            return try DiaryEntryMapper.toDomain(entity)
        }
    }

    func softDeleteEntry(entryID: UUID, requestingProfileID: UUID, deletedAt: Date) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = DiaryEntryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entryID as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else {
                throw DomainError.diaryEntryNotFound
            }
            guard entity.authorProfileID == requestingProfileID else {
                throw DomainError.notDiaryEntryAuthor
            }
            entity.isSoftDeleted = true
            entity.deletedAt = deletedAt
            try context.save()
        }
    }
}
