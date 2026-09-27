import Foundation

/// Revokes a Circle owner's active invite code. Failure here must remain
/// retryable — this Use Case does not swallow errors or mutate any other
/// local state, so a caller can simply call it again.
struct RevokeCircleInviteCodeUseCase: Sendable {
    let circleInviteCodeRepository: CircleInviteCodeRepository

    func execute(code: CircleInviteCode) async throws {
        try await circleInviteCodeRepository.revoke(code)
    }
}
