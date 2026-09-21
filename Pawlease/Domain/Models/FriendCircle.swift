import Foundation

/// A private group of two to five close friends who jointly care for one
/// `SharedPet`. The Circle's own time zone — not the device's — governs
/// what "today" means for every member.
struct FriendCircle: Sendable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let timezoneIdentifier: String
    let createdAt: Date
    let ownerProfileID: UUID
}
