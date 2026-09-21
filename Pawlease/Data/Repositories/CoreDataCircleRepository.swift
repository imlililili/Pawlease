import CoreData
import Foundation

nonisolated final class CoreDataCircleRepository: CircleRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchDefaultCircle() async throws -> FriendCircle? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = CircleEntity.fetchRequest()
            request.fetchLimit = 1
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            guard let entity = try context.fetch(request).first else { return nil }
            return CircleMapper.toDomain(entity)
        }
    }

    @discardableResult
    func saveCircle(_ circle: FriendCircle) async throws -> FriendCircle {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = CircleEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", circle.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? CircleEntity(context: context)
            CircleMapper.apply(circle, to: entity)
            try context.save()
            return CircleMapper.toDomain(entity)
        }
    }
}
