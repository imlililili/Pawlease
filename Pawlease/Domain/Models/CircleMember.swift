import Foundation

enum CircleMemberRole: String, Sendable, Equatable {
    case owner
    case member
}

/// A person's membership within one `FriendCircle`.
struct CircleMember: Sendable, Equatable, Identifiable {
    let id: UUID
    let circleID: UUID
    let profileID: UUID
    let displayName: String
    let avatarEmoji: String
    let joinedAt: Date
    let role: CircleMemberRole
}
