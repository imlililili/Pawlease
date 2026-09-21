import Foundation

/// Persists and retrieves `CircleMember` records for a `FriendCircle`.
protocol MemberRepository: Sendable {
    func fetchMembers(circleID: UUID) async throws -> [CircleMember]
    @discardableResult
    func saveMember(_ member: CircleMember) async throws -> CircleMember
}
