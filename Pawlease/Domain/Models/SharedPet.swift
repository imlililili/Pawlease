import Foundation

/// The one virtual pet a Circle jointly cares for. `stage` and
/// `growthPoints` only ever move forward — a missed day never deletes pet
/// growth. Day-to-day condition is represented separately by
/// `PetActivityState`, which is derived rather than stored.
struct SharedPet: Sendable, Equatable, Identifiable {
    let id: UUID
    let circleID: UUID
    let name: String
    let speciesKey: String
    let stage: PetLifeStage
    let growthPoints: Int
    let createdAt: Date
}
