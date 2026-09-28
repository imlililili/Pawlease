import Testing
import Foundation
@testable import Pawlease

struct DeleteDiaryEntryUseCaseTests {
    private func makeEntry(authorID: UUID) throws -> DiaryEntry {
        DiaryEntry(
            id: UUID(), circleID: UUID(), authorProfileID: authorID,
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("a thought"), visibilityDuration: .permanent,
            createdAt: Date(), expiresAt: nil, isDeleted: false, deletedAt: nil
        )
    }

    @Test
    func theAuthorCanDeleteTheirOwnEntry() async throws {
        let authorID = UUID()
        let entry = try makeEntry(authorID: authorID)
        let repository = InMemoryDiaryEntryRepository()
        repository.entries = [entry]
        let deletedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let useCase = DeleteDiaryEntryUseCase(diaryEntryRepository: repository, clock: FakeClock(now: deletedAt))

        try await useCase.execute(entryID: entry.id, requestingProfileID: authorID)

        let stored = repository.entries.first { $0.id == entry.id }
        #expect(stored?.isDeleted == true)
        #expect(stored?.deletedAt == deletedAt)
    }

    @Test
    func onlyTheAuthorCanDeleteTheEntry() async throws {
        let authorID = UUID()
        let someoneElse = UUID()
        let entry = try makeEntry(authorID: authorID)
        let repository = InMemoryDiaryEntryRepository()
        repository.entries = [entry]
        let useCase = DeleteDiaryEntryUseCase(diaryEntryRepository: repository, clock: FakeClock(now: Date()))

        await #expect(throws: DomainError.notDiaryEntryAuthor) {
            try await useCase.execute(entryID: entry.id, requestingProfileID: someoneElse)
        }
        let stored = repository.entries.first { $0.id == entry.id }
        #expect(stored?.isDeleted == false)
    }

    @Test
    func deletingAMissingEntryThrowsDiaryEntryNotFound() async throws {
        let repository = InMemoryDiaryEntryRepository()
        let useCase = DeleteDiaryEntryUseCase(diaryEntryRepository: repository, clock: FakeClock(now: Date()))

        await #expect(throws: DomainError.diaryEntryNotFound) {
            try await useCase.execute(entryID: UUID(), requestingProfileID: UUID())
        }
    }
}
