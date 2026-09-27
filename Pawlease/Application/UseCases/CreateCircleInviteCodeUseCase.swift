import Foundation

/// Creates (or replaces) the owner's invite code for a Circle: ensures a
/// `CKShare` exists (reusing one rather than duplicating it — delegated
/// entirely to `PrepareCircleInvitationUseCase`), supersedes/revokes any
/// previous active code, then publishes a fresh code — retrying on the
/// unlikely record-ID collision up to `maxCollisionRetries` times.
struct CreateCircleInviteCodeUseCase: Sendable {
    let prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase
    let circleInviteCodeRepository: CircleInviteCodeRepository
    let clock: ClockProviding
    let maxCollisionRetries: Int

    init(
        prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase,
        circleInviteCodeRepository: CircleInviteCodeRepository,
        clock: ClockProviding,
        maxCollisionRetries: Int = 5
    ) {
        self.prepareCircleInvitationUseCase = prepareCircleInvitationUseCase
        self.circleInviteCodeRepository = circleInviteCodeRepository
        self.clock = clock
        self.maxCollisionRetries = maxCollisionRetries
    }

    func execute(circleID: UUID) async throws -> CircleInviteCodeDetails {
        let preparedShare = try await prepareCircleInvitationUseCase.execute(circleID: circleID)
        guard let shareURL = preparedShare.shareURL, shareURL.scheme?.lowercased() == "https" else {
            throw CircleInviteCodeError.shareURLUnavailable
        }

        // A replacement code supersedes the previous one. Best-effort: if
        // there was no previous code, or revoking it fails, publishing the
        // new code still proceeds — an old code simply expires on its own
        // 48-hour clock in the worst case.
        if let existing = try? await circleInviteCodeRepository.fetchActiveCode(circleID: circleID) {
            try? await circleInviteCodeRepository.revoke(existing.code)
        }

        var attempts = 0
        while attempts < maxCollisionRetries {
            attempts += 1
            let now = clock.now
            let details = CircleInviteCodeDetails(
                code: .generateRandom(),
                circleID: circleID,
                shareURL: shareURL,
                createdAt: now,
                expiresAt: now.addingTimeInterval(CircleInviteCode.validityDuration),
                isRevoked: false
            )
            do {
                return try await circleInviteCodeRepository.publish(details)
            } catch CircleInviteCodeError.collision {
                continue
            }
        }
        throw CircleInviteCodeError.retryLimitExceeded
    }
}
