import Foundation

/// Persists and retrieves `CircleMember` records for a `FriendCircle`.
protocol MemberRepository: Sendable {
    func fetchMembers(circleID: UUID) async throws -> [CircleMember]
    @discardableResult
    func saveMember(_ member: CircleMember) async throws -> CircleMember
    /// Deletes the member matching this exact `(circleID, profileID)` pair,
    /// if one exists. A no-op if none matches. Deliberately narrow — no
    /// bulk or display-name-based deletion exists on this protocol — see
    /// `CleanUpLegacyDemoFriendUseCase` for its one intended caller.
    func deleteMember(circleID: UUID, profileID: UUID) async throws
}
