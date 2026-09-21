import Foundation

/// Persists and retrieves `DailyMoment`s. `saveMoment` upserts: publishing a
/// second moment for the same author and day replaces the first rather than
/// creating a duplicate contributor (see `PublishDailyMomentUseCase`).
protocol MomentRepository: Sendable {
    func fetchMoments(circleID: UUID, day: CircleDay) async throws -> [DailyMoment]
    func fetchMoments(circleID: UUID, days: [CircleDay]) async throws -> [DailyMoment]
    func hasMemberPosted(circleID: UUID, profileID: UUID, day: CircleDay) async throws -> Bool
    @discardableResult
    func saveMoment(_ moment: DailyMoment) async throws -> DailyMoment
}
