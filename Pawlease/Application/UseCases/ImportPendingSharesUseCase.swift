import Foundation

/// Reads every pending Share Extension inbox item and imports each as a
/// `PendingPostDraft`, skipping any draft ID already imported. A failed
/// import for one item never blocks the others and stays retryable on the
/// next run — the manifest is only removed after a successful save.
struct ImportPendingSharesUseCase: Sendable {
    let shareInboxStore: ShareInboxStoring
    let pendingPostDraftRepository: PendingPostDraftRepository

    @discardableResult
    func execute() async -> [PendingPostDraft] {
        let manifests = shareInboxStore.loadPendingManifests()
        var imported: [PendingPostDraft] = []

        for manifest in manifests {
            do {
                if let existing = try await pendingPostDraftRepository.fetchDraft(id: manifest.id) {
                    // Already imported on a previous run (e.g. the manifest
                    // removal was interrupted last time) — finish the
                    // idempotent cleanup and move on without re-saving.
                    shareInboxStore.removeManifest(id: manifest.id)
                    imported.append(existing)
                    continue
                }

                let draft = PendingPostDraft(
                    id: manifest.id,
                    caption: manifest.caption,
                    localImagePath: manifest.imageFilename,
                    createdAt: manifest.createdAt,
                    source: manifest.source
                )
                let saved = try await pendingPostDraftRepository.saveDraft(draft)
                // Only the manifest is removed here — the image file is
                // still needed by the draft we just saved.
                shareInboxStore.removeManifest(id: manifest.id)
                imported.append(saved)
            } catch {
                // Leave this manifest in place so it's retried next time.
                continue
            }
        }

        return imported
    }
}
