import Foundation

/// One member's published update for a single `CircleDay`: a photo, a short
/// caption, and an optional mood. A member may have at most one `DailyMoment`
/// per Circle day (see `PublishDailyMomentUseCase`).
struct DailyMoment: Sendable, Equatable, Identifiable {
    let id: UUID
    let circleID: UUID
    let authorProfileID: UUID
    let authorNameSnapshot: String
    let day: CircleDay
    let caption: MomentCaption
    let moodEmoji: String?
    let photo: MomentPhoto
    let createdAt: Date
}
