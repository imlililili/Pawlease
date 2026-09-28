import Foundation

/// Persists and retrieves `DiaryCommentReaction`s. Implementations must
/// enforce at most one reaction per (comment, member) pair — `saveReaction`
/// upserts rather than appends.
protocol DiaryCommentReactionRepository: Sendable {
    func fetchReactions(commentID: UUID) async throws -> [DiaryCommentReaction]
    func reaction(commentID: UUID, memberProfileID: UUID) async throws -> DiaryCommentReaction?
    func saveReaction(_ reaction: DiaryCommentReaction) async throws
    func removeReaction(commentID: UUID, memberProfileID: UUID) async throws
}
