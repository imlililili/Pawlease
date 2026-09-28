import Foundation

/// Mirrors `ReactToDiaryEntryUseCase`'s create/replace/remove rule, but for
/// a member reacting to a `DiaryComment` instead of the entry itself.
struct ReactToDiaryCommentUseCase: Sendable {
    enum Outcome: Sendable, Equatable {
        case added(DiaryCommentReaction)
        case replaced(DiaryCommentReaction)
        case removed
    }

    let diaryCommentReactionRepository: DiaryCommentReactionRepository
    let clock: ClockProviding

    @discardableResult
    func execute(commentID: UUID, memberProfileID: UUID, emoji: DiaryReactionEmoji) async throws -> Outcome {
        if let existing = try await diaryCommentReactionRepository.reaction(commentID: commentID, memberProfileID: memberProfileID) {
            if existing.emoji == emoji {
                try await diaryCommentReactionRepository.removeReaction(commentID: commentID, memberProfileID: memberProfileID)
                return .removed
            }
            let replacement = DiaryCommentReaction(
                id: existing.id,
                commentID: commentID,
                memberProfileID: memberProfileID,
                emoji: emoji,
                createdAt: existing.createdAt
            )
            try await diaryCommentReactionRepository.saveReaction(replacement)
            return .replaced(replacement)
        }

        let created = DiaryCommentReaction(
            id: UUID(),
            commentID: commentID,
            memberProfileID: memberProfileID,
            emoji: emoji,
            createdAt: clock.now
        )
        try await diaryCommentReactionRepository.saveReaction(created)
        return .added(created)
    }
}
