import Foundation

/// Loads the raw image bytes for a `PendingPostDraft` so the Post Composer
/// can prefill its preview. A local file read is fast enough to stay
/// synchronous; failures return `nil` rather than throwing, since a missing
/// image shouldn't crash the composer — it just won't have a preview.
struct LoadPendingDraftImageUseCase: Sendable {
    let shareInboxStore: ShareInboxStoring

    func execute(for draft: PendingPostDraft) -> Data? {
        shareInboxStore.loadImageData(filename: draft.localImagePath)
    }
}
