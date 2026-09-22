import Foundation

/// Persists and retrieves `CommentReaction`s. Implementations must enforce at
/// most one reaction per (comment, member) pair — `saveReaction` upserts
/// rather than appends.
protocol CommentReactionRepository: Sendable {
    func fetchReactions(commentID: UUID) async throws -> [CommentReaction]
    func reaction(commentID: UUID, memberProfileID: UUID) async throws -> CommentReaction?
    func saveReaction(_ reaction: CommentReaction) async throws
    func removeReaction(commentID: UUID, memberProfileID: UUID) async throws
}
