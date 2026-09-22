import Foundation

/// Soft-deletes a comment. Only the comment's own author may remove it — the
/// authorization check happens here, in the Application layer, not in the
/// Data layer or a ViewModel.
struct RemoveCommentUseCase: Sendable {
    let commentRepository: CommentRepository

    func execute(commentID: UUID, requestingMemberID: UUID) async throws {
        guard let comment = try await commentRepository.fetchComment(commentID: commentID) else {
            throw DomainError.commentNotFound
        }
        guard comment.authorProfileID == requestingMemberID else {
            throw DomainError.notCommentAuthor
        }
        try await commentRepository.softDeleteComment(commentID: commentID, requestingMemberID: requestingMemberID)
    }
}
