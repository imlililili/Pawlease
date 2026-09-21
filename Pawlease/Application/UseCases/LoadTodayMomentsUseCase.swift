import Foundation

/// Loads the current Circle day's moments, enforcing the post-to-unlock
/// rule via `CanViewTodayFeedUseCase` before returning anything.
struct LoadTodayMomentsUseCase: Sendable {
    let momentRepository: MomentRepository
    let canViewTodayFeed: CanViewTodayFeedUseCase

    init(momentRepository: MomentRepository, canViewTodayFeed: CanViewTodayFeedUseCase? = nil) {
        self.momentRepository = momentRepository
        self.canViewTodayFeed = canViewTodayFeed ?? CanViewTodayFeedUseCase(momentRepository: momentRepository)
    }

    func execute(circleID: UUID, requestingProfileID: UUID, day: CircleDay) async throws -> [DailyMoment] {
        let unlocked = try await canViewTodayFeed.execute(
            circleID: circleID,
            profileID: requestingProfileID,
            day: day
        )
        guard unlocked else {
            throw DomainError.feedLocked
        }
        let moments = try await momentRepository.fetchMoments(circleID: circleID, day: day)
        return moments.sorted { $0.createdAt > $1.createdAt }
    }
}
