import Foundation
@testable import Pawlease

/// Configurable test double for `CommentRepository`: stubbed results,
/// injectable errors, captured arguments, and invocation counts.
final class MockCommentRepository: CommentRepository, @unchecked Sendable {
    var fetchCommentsResult: [MomentComment] = []
    var fetchCommentsError: Error?
    private(set) var fetchCommentsCallCount = 0
    private(set) var fetchCommentsCapturedMomentIDs: [UUID] = []

    var fetchCommentResult: MomentComment?
    var fetchCommentError: Error?
    private(set) var fetchCommentCallCount = 0
    private(set) var fetchCommentCapturedIDs: [UUID] = []

    var saveCommentResult: MomentComment?
    var saveCommentError: Error?
    private(set) var saveCommentCallCount = 0
    private(set) var savedComments: [MomentComment] = []

    var softDeleteCommentError: Error?
    private(set) var softDeleteCommentCallCount = 0
    private(set) var softDeleteCommentCapturedArguments: [(commentID: UUID, requestingMemberID: UUID)] = []

    func fetchComments(momentID: UUID) async throws -> [MomentComment] {
        fetchCommentsCallCount += 1
        fetchCommentsCapturedMomentIDs.append(momentID)
        if let fetchCommentsError { throw fetchCommentsError }
        return fetchCommentsResult
    }

    func fetchComment(commentID: UUID) async throws -> MomentComment? {
        fetchCommentCallCount += 1
        fetchCommentCapturedIDs.append(commentID)
        if let fetchCommentError { throw fetchCommentError }
        return fetchCommentResult
    }

    @discardableResult
    func saveComment(_ comment: MomentComment) async throws -> MomentComment {
        saveCommentCallCount += 1
        savedComments.append(comment)
        if let saveCommentError { throw saveCommentError }
        return saveCommentResult ?? comment
    }

    func softDeleteComment(commentID: UUID, requestingMemberID: UUID) async throws {
        softDeleteCommentCallCount += 1
        softDeleteCommentCapturedArguments.append((commentID, requestingMemberID))
        if let softDeleteCommentError { throw softDeleteCommentError }
    }
}
