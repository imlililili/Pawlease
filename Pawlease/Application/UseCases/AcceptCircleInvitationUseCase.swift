/// Accepts whatever CloudKit share invitation is currently staged (by the
/// application lifecycle, via a Data/Infrastructure-layer coordinator — see
/// `CircleSharingRepository.acceptPendingInvitation()`), imports the shared
/// Circle into the shared store, and lets the caller refresh Circle state
/// afterward. Reports failure through the thrown error rather than
/// crashing; never deletes any existing local Circle data.
struct AcceptCircleInvitationUseCase: Sendable {
    let circleSharingRepository: CircleSharingRepository

    func execute() async throws {
        try await circleSharingRepository.acceptPendingInvitation()
    }
}
