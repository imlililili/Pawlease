import Foundation

/// Persists and retrieves `DiaryComment`s. Deletion is always soft: the
/// record is retained with `isRemoved = true` rather than erased.
protocol DiaryCommentRepository: Sendable {
    func fetchComments(entryID: UUID) async throws -> [DiaryComment]
    func fetchComment(commentID: UUID) async throws -> DiaryComment?
    @discardableResult
    func saveComment(_ comment: DiaryComment) async throws -> DiaryComment
    func softDeleteComment(commentID: UUID, requestingMemberID: UUID) async throws
}
