import Foundation

/// Persists and retrieves `FriendCircle` aggregates. Implemented in the Data
/// layer; the Domain and Application layers depend only on this protocol.
protocol CircleRepository: Sendable {
    func fetchDefaultCircle() async throws -> FriendCircle?
    /// Fetches a specific Circle by ID — used where the caller has already
    /// determined exactly which Circle it means (e.g. from
    /// `AcceptedCircleHandoff`) and must not fall back to
    /// `fetchDefaultCircle()`'s single-Circle-per-device assumption.
    func fetchCircle(id: UUID) async throws -> FriendCircle?
    @discardableResult
    func saveCircle(_ circle: FriendCircle) async throws -> FriendCircle
}
