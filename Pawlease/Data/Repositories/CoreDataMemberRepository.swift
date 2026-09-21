import CoreData
import Foundation

nonisolated final class CoreDataMemberRepository: MemberRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchMembers(circleID: UUID) async throws -> [CircleMember] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = MemberEntity.fetchRequest()
            request.predicate = NSPredicate(format: "circle.id == %@", circleID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "joinedAt", ascending: true)]
            return try context.fetch(request).map(MemberMapper.toDomain)
        }
    }

    @discardableResult
    func saveMember(_ member: CircleMember) async throws -> CircleMember {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let circleRequest = CircleEntity.fetchRequest()
            circleRequest.predicate = NSPredicate(format: "id == %@", member.circleID as CVarArg)
            circleRequest.fetchLimit = 1
            guard let circleEntity = try context.fetch(circleRequest).first else {
                throw DomainError.circleNotFound
            }

            let request = MemberEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", member.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? MemberEntity(context: context)
            MemberMapper.apply(member, to: entity)
            entity.circle = circleEntity
            try context.save()
            return MemberMapper.toDomain(entity)
        }
    }
}
