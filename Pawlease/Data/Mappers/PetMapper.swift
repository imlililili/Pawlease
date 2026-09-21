import Foundation

enum PetMapper {
    static func toDomain(_ entity: PetEntity) -> SharedPet {
        SharedPet(
            id: entity.id ?? UUID(),
            circleID: entity.circle?.id ?? UUID(),
            name: entity.name ?? "",
            speciesKey: entity.speciesKey ?? "fox",
            stage: PetLifeStage(rawValue: entity.stage) ?? .egg,
            growthPoints: Int(entity.growthPoints),
            createdAt: entity.createdAt ?? Date()
        )
    }

    static func apply(_ pet: SharedPet, to entity: PetEntity) {
        entity.id = pet.id
        entity.name = pet.name
        entity.speciesKey = pet.speciesKey
        entity.stage = pet.stage.rawValue
        entity.growthPoints = Int32(pet.growthPoints)
        entity.createdAt = pet.createdAt
    }
}
