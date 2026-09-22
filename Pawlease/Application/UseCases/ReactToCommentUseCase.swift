import Foundation

/// Mirrors `ReactToMomentUseCase`'s create/replace/remove rule, but for a
/// member reacting to a `MomentComment` instead of the moment itself.
struct ReactToCommentUseCase: Sendable {
    enum Outcome: Sendable, Equatable {
        case added(CommentReaction)
        case replaced(CommentReaction)
        case removed
    }

    let commentReactionRepository: CommentReactionRepository
    let clock: ClockProviding

    @discardableResult
    func execute(commentID: UUID, memberProfileID: UUID, emoji: ReactionEmoji) async throws -> Outcome {
        if let existing = try await commentReactionRepository.reaction(commentID: commentID, memberProfileID: memberProfileID) {
            if existing.emoji == emoji {
                try await commentReactionRepository.removeReaction(commentID: commentID, memberProfileID: memberProfileID)
                return .removed
            }
            let replacement = CommentReaction(
                id: existing.id,
                commentID: commentID,
                memberProfileID: memberProfileID,
                emoji: emoji,
                createdAt: existing.createdAt
            )
            try await commentReactionRepository.saveReaction(replacement)
            return .replaced(replacement)
        }

        let created = CommentReaction(
            id: UUID(),
            commentID: commentID,
            memberProfileID: memberProfileID,
            emoji: emoji,
            createdAt: clock.now
        )
        try await commentReactionRepository.saveReaction(created)
        return .added(created)
    }
}
