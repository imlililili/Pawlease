/// Reloads the semantic Circle snapshot in response to a store change —
/// either a user-initiated pull-to-refresh, or a CloudKit-driven remote
/// change pulse from `RemoteChangeSignaling`. Never polls CloudKit on a
/// repeating timer; this only re-reads whatever Core Data already has.
struct RefreshSharedCircleUseCase: Sendable {
    let loadPetHomeUseCase: LoadPetHomeUseCase

    @discardableResult
    func execute() async throws -> PetHomeSnapshot {
        try await loadPetHomeUseCase.execute()
    }
}
