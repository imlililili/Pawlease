import Foundation

/// Persists and retrieves `MomentComment`s. Deletion is always soft: the
/// record is retained with `isRemoved = true` rather than erased.
protocol CommentRepository: Sendable {
    func fetchComments(momentID: UUID) async throws -> [MomentComment]
    func fetchComment(commentID: UUID) async throws -> MomentComment?
    @discardableResult
    func saveComment(_ comment: MomentComment) async throws -> MomentComment
    func softDeleteComment(commentID: UUID, requestingMemberID: UUID) async throws
}
