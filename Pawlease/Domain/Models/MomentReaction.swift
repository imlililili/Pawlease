import Foundation

/// One member's emoji reaction to a `DailyMoment`. Persisted as an
/// individual, per-member row — never an increment-only counter — so
/// reactions can later merge safely through CloudKit sync. At most one
/// `MomentReaction` exists per (moment, member) pair; see
/// `ReactToMomentUseCase` for the create/replace/remove rule.
struct MomentReaction: Identifiable, Sendable, Equatable {
    let id: UUID
    let momentID: UUID
    let memberProfileID: UUID
    let emoji: ReactionEmoji
    let createdAt: Date
}
