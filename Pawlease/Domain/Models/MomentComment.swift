import Foundation

/// A single-level comment on a `DailyMoment`. No nested replies, no editing —
/// only a soft-delete via `isRemoved`. The `body` always carries the
/// originally stored text; it's the Presentation layer's job to display
/// "Comment removed" instead when `isRemoved` is true, so the underlying
/// record (id, author, timestamp) stays intact for moderation/history.
struct MomentComment: Identifiable, Sendable, Equatable {
    let id: UUID
    let momentID: UUID
    let authorProfileID: UUID
    let authorNameSnapshot: String
    let body: CommentBody
    let createdAt: Date
    let isRemoved: Bool
}
