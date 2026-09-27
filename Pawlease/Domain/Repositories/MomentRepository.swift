import Foundation

/// Persists and retrieves `DailyMoment`s. `saveMoment` upserts: publishing a
/// second moment for the same author and day replaces the first rather than
/// creating a duplicate contributor (see `PublishDailyMomentUseCase`).
protocol MomentRepository: Sendable {
    func fetchMoment(id: UUID) async throws -> DailyMoment?
    func fetchMoments(circleID: UUID, day: CircleDay) async throws -> [DailyMoment]
    func fetchMoments(circleID: UUID, days: [CircleDay]) async throws -> [DailyMoment]
    func hasMemberPosted(circleID: UUID, profileID: UUID, day: CircleDay) async throws -> Bool
    @discardableResult
    func saveMoment(_ moment: DailyMoment) async throws -> DailyMoment
    /// Deletes every moment authored by this exact `(circleID,
    /// authorProfileID)` pair. A no-op if none match. Deliberately narrow —
    /// see `CleanUpLegacyDemoFriendUseCase` for its one intended caller.
    func deleteMoments(circleID: UUID, authorProfileID: UUID) async throws
}
