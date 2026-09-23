import Foundation

/// Persists and retrieves the current device's local `UserProfile`.
protocol UserProfileRepository: Sendable {
    /// Returns the existing local profile, or creates and persists exactly
    /// one if none exists yet. Never creates a second profile on repeated
    /// calls.
    func fetchOrCreateCurrentProfile() async throws -> UserProfile
}
