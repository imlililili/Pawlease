import Foundation

/// Applies the tri-state reaction rule for a member reacting to a
/// `DailyMoment`: no existing reaction creates one, an existing different
/// emoji replaces it in place, and re-selecting the same emoji removes it.
/// Reactions are always persisted as individual member rows — never an
/// increment-only counter — so they can later merge safely through CloudKit.
struct ReactToMomentUseCase: Sendable {
    enum Outcome: Sendable, Equatable {
        case added(MomentReaction)
        case replaced(MomentReaction)
        case removed
    }

    let momentReactionRepository: MomentReactionRepository
    let clock: ClockProviding

    @discardableResult
    func execute(momentID: UUID, memberProfileID: UUID, emoji: ReactionEmoji) async throws -> Outcome {
        if let existing = try await momentReactionRepository.reaction(momentID: momentID, memberProfileID: memberProfileID) {
            if existing.emoji == emoji {
                try await momentReactionRepository.removeReaction(momentID: momentID, memberProfileID: memberProfileID)
                return .removed
            }
            let replacement = MomentReaction(
                id: existing.id,
                momentID: momentID,
                memberProfileID: memberProfileID,
                emoji: emoji,
                createdAt: existing.createdAt
            )
            try await momentReactionRepository.saveReaction(replacement)
            return .replaced(replacement)
        }

        let created = MomentReaction(
            id: UUID(),
            momentID: momentID,
            memberProfileID: memberProfileID,
            emoji: emoji,
            createdAt: clock.now
        )
        try await momentReactionRepository.saveReaction(created)
        return .added(created)
    }
}
