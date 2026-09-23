import Foundation
@testable import Pawlease

final class MockPendingPostDraftRepository: PendingPostDraftRepository, @unchecked Sendable {
    var drafts: [UUID: PendingPostDraft] = [:]
    var fetchAllError: Error?
    var saveDraftError: Error?

    private(set) var fetchAllCallCount = 0
    private(set) var fetchDraftCallCount = 0
    private(set) var saveDraftCallCount = 0
    private(set) var savedDrafts: [PendingPostDraft] = []
    private(set) var deleteDraftCallCount = 0
    private(set) var deletedDraftIDs: [UUID] = []

    func fetchAll() async throws -> [PendingPostDraft] {
        fetchAllCallCount += 1
        if let fetchAllError { throw fetchAllError }
        return drafts.values.sorted { $0.createdAt < $1.createdAt }
    }

    func fetchDraft(id: UUID) async throws -> PendingPostDraft? {
        fetchDraftCallCount += 1
        return drafts[id]
    }

    @discardableResult
    func saveDraft(_ draft: PendingPostDraft) async throws -> PendingPostDraft {
        saveDraftCallCount += 1
        if let saveDraftError { throw saveDraftError }
        drafts[draft.id] = draft
        savedDrafts.append(draft)
        return draft
    }

    func deleteDraft(id: UUID) async throws {
        deleteDraftCallCount += 1
        deletedDraftIDs.append(id)
        drafts.removeValue(forKey: id)
    }
}
