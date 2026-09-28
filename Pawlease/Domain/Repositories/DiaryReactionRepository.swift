import Foundation

/// Persists and retrieves `DiaryReaction`s. Implementations must enforce at
/// most one reaction per (entry, member) pair — `saveReaction` upserts
/// rather than appends.
protocol DiaryReactionRepository: Sendable {
    func fetchReactions(entryID: UUID) async throws -> [DiaryReaction]
    func reaction(entryID: UUID, memberProfileID: UUID) async throws -> DiaryReaction?
    func saveReaction(_ reaction: DiaryReaction) async throws
    func removeReaction(entryID: UUID, memberProfileID: UUID) async throws
}
