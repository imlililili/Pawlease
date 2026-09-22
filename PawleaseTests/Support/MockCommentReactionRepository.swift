import Foundation
@testable import Pawlease

/// Configurable test double for `CommentReactionRepository`: stubbed
/// results, injectable errors, captured arguments, and invocation counts.
final class MockCommentReactionRepository: CommentReactionRepository, @unchecked Sendable {
    var fetchReactionsResult: [CommentReaction] = []

    var reactionResult: CommentReaction?
    var reactionError: Error?
    private(set) var reactionCallCount = 0

    var saveReactionError: Error?
    private(set) var saveReactionCallCount = 0
    private(set) var savedReactions: [CommentReaction] = []

    var removeReactionError: Error?
    private(set) var removeReactionCallCount = 0
    private(set) var removeReactionCapturedArguments: [(commentID: UUID, memberProfileID: UUID)] = []

    func fetchReactions(commentID: UUID) async throws -> [CommentReaction] {
        fetchReactionsResult
    }

    func reaction(commentID: UUID, memberProfileID: UUID) async throws -> CommentReaction? {
        reactionCallCount += 1
        if let reactionError { throw reactionError }
        return reactionResult
    }

    func saveReaction(_ reaction: CommentReaction) async throws {
        saveReactionCallCount += 1
        savedReactions.append(reaction)
        if let saveReactionError { throw saveReactionError }
    }

    func removeReaction(commentID: UUID, memberProfileID: UUID) async throws {
        removeReactionCallCount += 1
        removeReactionCapturedArguments.append((commentID, memberProfileID))
        if let removeReactionError { throw removeReactionError }
    }
}
