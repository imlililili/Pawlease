import Foundation

/// Persists and retrieves the `SharedPet` belonging to a `FriendCircle`.
protocol PetRepository: Sendable {
    func fetchPet(circleID: UUID) async throws -> SharedPet?
    @discardableResult
    func savePet(_ pet: SharedPet) async throws -> SharedPet
}
