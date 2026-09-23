import Foundation

/// Persists and retrieves `PendingPostDraft`s using the existing
/// `PendingPostDraftEntity`. `saveDraft` upserts by id — the Use Case layer
/// (not a Core Data unique constraint) is responsible for deciding whether
/// a given draft ID should be imported at all.
protocol PendingPostDraftRepository: Sendable {
    func fetchAll() async throws -> [PendingPostDraft]
    func fetchDraft(id: UUID) async throws -> PendingPostDraft?
    @discardableResult
    func saveDraft(_ draft: PendingPostDraft) async throws -> PendingPostDraft
    func deleteDraft(id: UUID) async throws
}
