import Foundation

/// Persists and retrieves `FriendCircle` aggregates. Implemented in the Data
/// layer; the Domain and Application layers depend only on this protocol.
protocol CircleRepository: Sendable {
    func fetchDefaultCircle() async throws -> FriendCircle?
    @discardableResult
    func saveCircle(_ circle: FriendCircle) async throws -> FriendCircle
}
