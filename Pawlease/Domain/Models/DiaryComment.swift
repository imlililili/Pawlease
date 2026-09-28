import Foundation

/// A single-level comment on a `DiaryEntry`. Mirrors `MomentComment`
/// exactly — same 60-character `CommentBody`, same soft-delete-only
/// policy — but targets a Diary entry instead of a Moment, kept as a
/// distinct type so a comment can never be attached to the wrong feed.
struct DiaryComment: Identifiable, Sendable, Equatable {
    let id: UUID
    let entryID: UUID
    let authorProfileID: UUID
    let authorNameSnapshot: String
    let body: CommentBody
    let createdAt: Date
    let isRemoved: Bool
}
