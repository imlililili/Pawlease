import Foundation

/// Loads every currently-pending draft (previously imported and not yet
/// published), oldest first.
struct LoadPendingDraftsUseCase: Sendable {
    let pendingPostDraftRepository: PendingPostDraftRepository

    func execute() async throws -> [PendingPostDraft] {
        try await pendingPostDraftRepository.fetchAll()
    }
}
