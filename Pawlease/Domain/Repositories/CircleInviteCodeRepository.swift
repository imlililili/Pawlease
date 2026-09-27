import Foundation

/// Persists and resolves public `CircleInviteCode` lookup records.
/// Implemented in the Data layer against CloudKit's public database — none
/// of that ever appears in this protocol's signatures. This is only a
/// lookup mechanism; it must never be treated as membership authorization.
protocol CircleInviteCodeRepository: Sendable {
    /// Publishes a new invite-code record. Callers are responsible for
    /// generating a fresh `CircleInviteCode` and retrying on `.collision`.
    @discardableResult
    func publish(_ details: CircleInviteCodeDetails) async throws -> CircleInviteCodeDetails

    /// The Circle owner's currently active (not yet revoked) code, if any —
    /// used to supersede/revoke a previous code when creating a new one, and
    /// to redisplay the active code without creating a duplicate. Looked up
    /// by `circleID`, so this is the one operation that queries rather than
    /// fetching by record ID.
    func fetchActiveCode(circleID: UUID) async throws -> CircleInviteCodeDetails?

    /// Resolves a code a friend typed in, by record ID. Throws `.notFound`
    /// if no record exists at that ID.
    func fetchCode(_ code: CircleInviteCode) async throws -> CircleInviteCodeDetails

    func revoke(_ code: CircleInviteCode) async throws
}
