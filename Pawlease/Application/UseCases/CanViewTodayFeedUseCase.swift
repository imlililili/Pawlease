import Foundation

/// A member may only view friends' current-day moments after publishing
/// their own moment for the same Circle day.
struct CanViewTodayFeedUseCase: Sendable {
    let momentRepository: MomentRepository

    func execute(circleID: UUID, profileID: UUID, day: CircleDay) async throws -> Bool {
        try await momentRepository.hasMemberPosted(circleID: circleID, profileID: profileID, day: day)
    }
}
