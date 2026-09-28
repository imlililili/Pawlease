import Foundation

/// One member's free-keyboard-emoji reaction to a `DiaryComment`. Mirrors
/// `DiaryReaction` but targets a comment instead of an entry — kept as a
/// separate semantic type so a reaction can never be attached to the wrong
/// kind of target.
struct DiaryCommentReaction: Identifiable, Sendable, Equatable {
    let id: UUID
    let commentID: UUID
    let memberProfileID: UUID
    let emoji: DiaryReactionEmoji
    let createdAt: Date
}
