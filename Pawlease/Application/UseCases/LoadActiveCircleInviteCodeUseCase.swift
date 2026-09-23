import Foundation

/// Reads the Circle owner's currently active invite code, if any — used to
/// redisplay it (e.g. on returning to Circle Settings) without creating a
/// duplicate.
struct LoadActiveCircleInviteCodeUseCase: Sendable {
    let circleInviteCodeRepository: CircleInviteCodeRepository

    func execute(circleID: UUID) async throws -> CircleInviteCodeDetails? {
        try await circleInviteCodeRepository.fetchActiveCode(circleID: circleID)
    }
}
