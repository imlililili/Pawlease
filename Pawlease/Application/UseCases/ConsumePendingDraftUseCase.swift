import Foundation

/// Cleans up a `PendingPostDraft` once it has been fully consumed — i.e.
/// its photo was actually published as a `DailyMoment`. Deletes both the
/// Core Data row and the underlying image file, since neither is needed
/// anymore. Never throws: cleanup failing here must not affect a
/// publish that already succeeded.
struct ConsumePendingDraftUseCase: Sendable {
    let pendingPostDraftRepository: PendingPostDraftRepository
    let shareInboxStore: ShareInboxStoring

    func execute(draftID: UUID, imageFilename: String) async {
        try? await pendingPostDraftRepository.deleteDraft(id: draftID)
        shareInboxStore.removeImage(filename: imageFilename)
    }
}
