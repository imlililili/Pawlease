import Foundation

/// Soft-deletes a Diary entry. Only the entry's own author may delete it —
/// the authorization check happens here, in the Application layer, not in
/// the Data layer or a ViewModel (though the repository re-checks it too,
/// as defense in depth — see `CoreDataDiaryEntryRepository`).
struct DeleteDiaryEntryUseCase: Sendable {
    let diaryEntryRepository: DiaryEntryRepository
    let clock: ClockProviding

    func execute(entryID: UUID, requestingProfileID: UUID) async throws {
        guard let entry = try await diaryEntryRepository.fetchEntry(entryID: entryID) else {
            throw DomainError.diaryEntryNotFound
        }
        guard entry.authorProfileID == requestingProfileID else {
            throw DomainError.notDiaryEntryAuthor
        }
        try await diaryEntryRepository.softDeleteEntry(
            entryID: entryID, requestingProfileID: requestingProfileID, deletedAt: clock.now
        )
    }
}
