import Foundation

/// One member's emoji reaction to a `MomentComment`. Mirrors `MomentReaction`
/// but targets a comment instead of a moment — kept as a separate semantic
/// type so a reaction can never be attached to the wrong kind of target.
struct CommentReaction: Identifiable, Sendable, Equatable {
    let id: UUID
    let commentID: UUID
    let memberProfileID: UUID
    let emoji: ReactionEmoji
    let createdAt: Date
}
