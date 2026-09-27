import Foundation

/// Resolves a friend's typed invite code to a `CKShare` URL: normalizes and
/// validates the code locally (rejecting malformed input before any
/// CloudKit request), looks it up in the public database, then checks it is
/// neither revoked nor expired. This is only a lookup step — the returned
/// `shareURL` still has to go through Apple's CKShare acceptance flow
/// before any Circle data becomes visible; resolving a code is never itself
/// authorization.
struct ResolveCircleInviteCodeUseCase: Sendable {
    let circleInviteCodeRepository: CircleInviteCodeRepository
    let clock: ClockProviding

    func execute(rawInput: String) async throws -> CircleInviteCodeDetails {
        guard let code = CircleInviteCode.parse(rawInput: rawInput) else {
            throw CircleInviteCodeError.malformed
        }

        let details = try await circleInviteCodeRepository.fetchCode(code)

        guard !details.isRevoked else {
            throw CircleInviteCodeError.revoked
        }
        guard !details.isExpired(asOf: clock.now) else {
            throw CircleInviteCodeError.expired
        }

        return details
    }
}
