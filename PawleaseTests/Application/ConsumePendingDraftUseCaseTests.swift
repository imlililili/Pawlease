import Testing
import Foundation
@testable import Pawlease

struct ConsumePendingDraftUseCaseTests {
    @Test
    func consumingADraftDeletesItAndItsImage() async {
        let draftRepo = MockPendingPostDraftRepository()
        let draftID = UUID()
        draftRepo.drafts[draftID] = PendingPostDraft(id: draftID, caption: nil, localImagePath: "a.jpg", createdAt: Date(), source: PendingShareSource.photosShareExtension)
        let inboxStore = MockShareInboxStore()

        let useCase = ConsumePendingDraftUseCase(pendingPostDraftRepository: draftRepo, shareInboxStore: inboxStore)
        await useCase.execute(draftID: draftID, imageFilename: "a.jpg")

        #expect(draftRepo.deletedDraftIDs == [draftID])
        #expect(inboxStore.removedImageFilenames == ["a.jpg"])
    }
}
