import CoreData
import Foundation

nonisolated final class CoreDataMomentRepository: MomentRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchMoment(id: UUID) async throws -> DailyMoment? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DailyPostEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else { return nil }
            return try MomentMapper.toDomain(entity)
        }
    }

    func fetchMoments(circleID: UUID, day: CircleDay) async throws -> [DailyMoment] {
        try await fetchMoments(circleID: circleID, dayValues: [day.value])
    }

    func fetchMoments(circleID: UUID, days: [CircleDay]) async throws -> [DailyMoment] {
        guard !days.isEmpty else { return [] }
        return try await fetchMoments(circleID: circleID, dayValues: days.map(\.value))
    }

    func hasMemberPosted(circleID: UUID, profileID: UUID, day: CircleDay) async throws -> Bool {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DailyPostEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "circle.id == %@ AND authorProfileID == %@ AND dayKey == %@",
                circleID as CVarArg, profileID as CVarArg, day.value
            )
            request.fetchLimit = 1
            return try context.count(for: request) > 0
        }
    }

    @discardableResult
    func saveMoment(_ moment: DailyMoment) async throws -> DailyMoment {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let circleRequest = CircleEntity.fetchRequest()
            circleRequest.predicate = NSPredicate(format: "id == %@", moment.circleID as CVarArg)
            circleRequest.fetchLimit = 1
            guard let circleEntity = try context.fetch(circleRequest).first else {
                throw DomainError.circleNotFound
            }

            let request = DailyPostEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", moment.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? DailyPostEntity(context: context)
            MomentMapper.apply(moment, to: entity)
            entity.circle = circleEntity
            try context.save()
            return try MomentMapper.toDomain(entity)
        }
    }

    private func fetchMoments(circleID: UUID, dayValues: [String]) async throws -> [DailyMoment] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = DailyPostEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "circle.id == %@ AND dayKey IN %@",
                circleID as CVarArg, dayValues
            )
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            return try context.fetch(request).map(MomentMapper.toDomain)
        }
    }
}
