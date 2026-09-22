import Foundation
@testable import Pawlease

/// Configurable test double for `MomentReactionRepository`: stubbed
/// results, injectable errors, captured arguments, and invocation counts.
final class MockMomentReactionRepository: MomentReactionRepository, @unchecked Sendable {
    var fetchReactionsResult: [MomentReaction] = []

    var reactionResult: MomentReaction?
    var reactionError: Error?
    private(set) var reactionCallCount = 0

    var saveReactionError: Error?
    private(set) var saveReactionCallCount = 0
    private(set) var savedReactions: [MomentReaction] = []

    var removeReactionError: Error?
    private(set) var removeReactionCallCount = 0
    private(set) var removeReactionCapturedArguments: [(momentID: UUID, memberProfileID: UUID)] = []

    func fetchReactions(momentID: UUID) async throws -> [MomentReaction] {
        fetchReactionsResult
    }

    func reaction(momentID: UUID, memberProfileID: UUID) async throws -> MomentReaction? {
        reactionCallCount += 1
        if let reactionError { throw reactionError }
        return reactionResult
    }

    func saveReaction(_ reaction: MomentReaction) async throws {
        saveReactionCallCount += 1
        savedReactions.append(reaction)
        if let saveReactionError { throw saveReactionError }
    }

    func removeReaction(momentID: UUID, memberProfileID: UUID) async throws {
        removeReactionCallCount += 1
        removeReactionCapturedArguments.append((momentID, memberProfileID))
        if let removeReactionError { throw removeReactionError }
    }
}
