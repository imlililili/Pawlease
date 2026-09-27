import Foundation

/// The current device's local user identity — backed by `UserProfileEntity`
/// in the `Private` Core Data configuration (never shared, syncs privately
/// across the signed-in user's own devices only). Used to determine which
/// `CircleMember` row, if any, represents "me" in a given Circle.
struct UserProfile: Sendable, Equatable, Identifiable {
    let id: UUID
    let displayName: String
    let avatarEmoji: String
    let createdAt: Date
}
