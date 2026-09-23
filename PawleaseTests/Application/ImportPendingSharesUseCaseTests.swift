import Testing
import Foundation
@testable import Pawlease

/// Mock-based only — never touches Core Data or CloudKit.
struct ImportPendingSharesUseCaseTests {
    @Test
    func oneValidSharedImageProducesAnInboxDraft() async {
        let inboxStore = MockShareInboxStore()
        let manifest = PendingShareManifest(id: UUID(), caption: "Hi", imageFilename: "a.jpg", createdAt: Date(), source: PendingShareSource.photosShareExtension)
        inboxStore.stubbedPendingManifests = [manifest]
        let draftRepo = MockPendingPostDraftRepository()
        let useCase = ImportPendingSharesUseCase(shareInboxStore: inboxStore, pendingPostDraftRepository: draftRepo)

        let imported = await useCase.execute()

        #expect(imported.count == 1)
        #expect(imported.first?.id == manifest.id)
        #expect(draftRepo.saveDraftCallCount == 1)
        #expect(inboxStore.removedManifestIDs == [manifest.id])
    }

    @Test
    func successfulImportCreatesAPendingPostDraftSemanticValue() async throws {
        let inboxStore = MockShareInboxStore()
        let manifest = PendingShareManifest(id: UUID(), caption: "Caption", imageFilename: "img.jpg", createdAt: Date(), source: PendingShareSource.photosShareExtension)
        inboxStore.stubbedPendingManifests = [manifest]
        let draftRepo = MockPendingPostDraftRepository()
        let useCase = ImportPendingSharesUseCase(shareInboxStore: inboxStore, pendingPostDraftRepository: draftRepo)

        let imported = await useCase.execute()

        let draft = try #require(imported.first)
        #expect(draft.caption == "Caption")
        #expect(draft.localImagePath == "img.jpg")
        #expect(draft.source == PendingShareSource.photosShareExtension)
    }

    @Test
    func twoSharesReceiveDifferentDraftIDsAndDoNotOverwriteEachOther() async {
        let inboxStore = MockShareInboxStore()
        let first = PendingShareManifest(id: UUID(), caption: nil, imageFilename: "a.jpg", createdAt: TestFactories.date(year: 2026, month: 9, day: 23, hour: 8), source: PendingShareSource.photosShareExtension)
        let second = PendingShareManifest(id: UUID(), caption: nil, imageFilename: "b.jpg", createdAt: TestFactories.date(year: 2026, month: 9, day: 23, hour: 9), source: PendingShareSource.photosShareExtension)
        inboxStore.stubbedPendingManifests = [first, second]
        let draftRepo = MockPendingPostDraftRepository()
        let useCase = ImportPendingSharesUseCase(shareInboxStore: inboxStore, pendingPostDraftRepository: draftRepo)

        let imported = await useCase.execute()

        #expect(imported.count == 2)
        #expect(Set(imported.map(\.id)).count == 2)
        #expect(draftRepo.savedDrafts.count == 2)
    }

    @Test
    func pendingInboxItemsImportInDeterministicOrder() async {
        let inboxStore = MockShareInboxStore()
        let earlier = PendingShareManifest(id: UUID(), caption: nil, imageFilename: "earlier.jpg", createdAt: TestFactories.date(year: 2026, month: 9, day: 23, hour: 8), source: PendingShareSource.photosShareExtension)
        let later = PendingShareManifest(id: UUID(), caption: nil, imageFilename: "later.jpg", createdAt: TestFactories.date(year: 2026, month: 9, day: 23, hour: 10), source: PendingShareSource.photosShareExtension)
        inboxStore.stubbedPendingManifests = [earlier, later]
        let draftRepo = MockPendingPostDraftRepository()
        let useCase = ImportPendingSharesUseCase(shareInboxStore: inboxStore, pendingPostDraftRepository: draftRepo)

        let imported = await useCase.execute()

        // The Use Case imports whatever order the store returns, in order —
        // the store itself (see AppGroupShareInboxStoreFilesystemTests) is
        // what guarantees createdAt-ascending ordering.
        #expect(imported.map(\.localImagePath) == ["earlier.jpg", "later.jpg"])
    }

    @Test
    func anAlreadyImportedDraftIDIsNotImportedTwice() async {
        let inboxStore = MockShareInboxStore()
        let manifest = PendingShareManifest(id: UUID(), caption: nil, imageFilename: "a.jpg", createdAt: Date(), source: PendingShareSource.photosShareExtension)
        inboxStore.stubbedPendingManifests = [manifest]

        let draftRepo = MockPendingPostDraftRepository()
        let existingDraft = PendingPostDraft(id: manifest.id, caption: "Already here", localImagePath: "a.jpg", createdAt: Date(), source: PendingShareSource.photosShareExtension)
        draftRepo.drafts[manifest.id] = existingDraft

        let useCase = ImportPendingSharesUseCase(shareInboxStore: inboxStore, pendingPostDraftRepository: draftRepo)
        _ = await useCase.execute()

        #expect(draftRepo.saveDraftCallCount == 0)
        // The stale manifest is still cleaned up even though nothing new was saved.
        #expect(inboxStore.removedManifestIDs == [manifest.id])
    }

    @Test
    func aFailedImportRemainsAvailableForRetry() async {
        let inboxStore = MockShareInboxStore()
        let manifest = PendingShareManifest(id: UUID(), caption: nil, imageFilename: "a.jpg", createdAt: Date(), source: PendingShareSource.photosShareExtension)
        inboxStore.stubbedPendingManifests = [manifest]

        let draftRepo = MockPendingPostDraftRepository()
        struct StubSaveError: Error {}
        draftRepo.saveDraftError = StubSaveError()

        let useCase = ImportPendingSharesUseCase(shareInboxStore: inboxStore, pendingPostDraftRepository: draftRepo)
        let imported = await useCase.execute()

        #expect(imported.isEmpty)
        // The manifest must NOT be removed on failure, so the next import pass retries it.
        #expect(inboxStore.removedManifestIDs.isEmpty)
        #expect(inboxStore.loadPendingManifests().contains(manifest))
    }
}
