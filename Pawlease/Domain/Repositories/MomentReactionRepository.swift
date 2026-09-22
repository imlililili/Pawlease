import Foundation

/// Persists and retrieves `MomentReaction`s. Implementations must enforce at
/// most one reaction per (moment, member) pair — `saveReaction` upserts
/// rather than appends.
protocol MomentReactionRepository: Sendable {
    func fetchReactions(momentID: UUID) async throws -> [MomentReaction]
    func reaction(momentID: UUID, memberProfileID: UUID) async throws -> MomentReaction?
    func saveReaction(_ reaction: MomentReaction) async throws
    func removeReaction(momentID: UUID, memberProfileID: UUID) async throws
}
