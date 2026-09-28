import Foundation

/// Applies the create/replace/remove reaction rule for a member reacting to
/// a `DiaryEntry`, using a free-keyboard `DiaryReactionEmoji` rather than
/// the fixed Moment reaction set. Mirrors `ReactToMomentUseCase` exactly.
struct ReactToDiaryEntryUseCase: Sendable {
    enum Outcome: Sendable, Equatable {
        case added(DiaryReaction)
        case replaced(DiaryReaction)
        case removed
    }

    let diaryReactionRepository: DiaryReactionRepository
    let clock: ClockProviding

    @discardableResult
    func execute(entryID: UUID, memberProfileID: UUID, emoji: DiaryReactionEmoji) async throws -> Outcome {
        if let existing = try await diaryReactionRepository.reaction(entryID: entryID, memberProfileID: memberProfileID) {
            if existing.emoji == emoji {
                try await diaryReactionRepository.removeReaction(entryID: entryID, memberProfileID: memberProfileID)
                return .removed
            }
            let replacement = DiaryReaction(
                id: existing.id,
                entryID: entryID,
                memberProfileID: memberProfileID,
                emoji: emoji,
                createdAt: existing.createdAt
            )
            try await diaryReactionRepository.saveReaction(replacement)
            return .replaced(replacement)
        }

        let created = DiaryReaction(
            id: UUID(),
            entryID: entryID,
            memberProfileID: memberProfileID,
            emoji: emoji,
            createdAt: clock.now
        )
        try await diaryReactionRepository.saveReaction(created)
        return .added(created)
    }
}
