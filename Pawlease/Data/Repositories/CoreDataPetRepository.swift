import CoreData
import Foundation

nonisolated final class CoreDataPetRepository: PetRepository, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchPet(circleID: UUID) async throws -> SharedPet? {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "circle.id == %@", circleID as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else { return nil }
            return PetMapper.toDomain(entity)
        }
    }

    @discardableResult
    func savePet(_ pet: SharedPet) async throws -> SharedPet {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let circleRequest = CircleEntity.fetchRequest()
            circleRequest.predicate = NSPredicate(format: "id == %@", pet.circleID as CVarArg)
            circleRequest.fetchLimit = 1
            guard let circleEntity = try context.fetch(circleRequest).first else {
                throw DomainError.circleNotFound
            }

            let request = PetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", pet.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? PetEntity(context: context)
            PetMapper.apply(pet, to: entity)
            entity.circle = circleEntity
            try context.save()
            return PetMapper.toDomain(entity)
        }
    }
}
