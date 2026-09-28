import Testing
import Foundation
@testable import Pawlease

struct LoadMyDiaryArchiveUseCaseTests {
    private func makeEntry(
        circleID: UUID,
        authorID: UUID,
        createdAt: Date,
        duration: DiaryVisibilityDuration
    ) throws -> DiaryEntry {
        DiaryEntry(
            id: UUID(), circleID: circleID, authorProfileID: authorID,
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("archived thought"), visibilityDuration: duration,
            createdAt: createdAt, expiresAt: duration.expiresAt(from: createdAt),
            isDeleted: false, deletedAt: nil
        )
    }

    @Test
    func onlyTheAuthorSeesTheirExpiredEntriesInMyArchive() async throws {
        let circleID = UUID()
        let me = UUID()
        let someoneElse = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let repository = InMemoryDiaryEntryRepository()

        let myExpired = try makeEntry(circleID: circleID, authorID: me, createdAt: now.addingTimeInterval(-25 * 3600), duration: .oneDay)
        let theirExpired = try makeEntry(circleID: circleID, authorID: someoneElse, createdAt: now.addingTimeInterval(-25 * 3600), duration: .oneDay)
        let myActive = try makeEntry(circleID: circleID, authorID: me, createdAt: now, duration: .oneDay)
        repository.entries = [myExpired, theirExpired, myActive]

        let useCase = LoadMyDiaryArchiveUseCase(diaryEntryRepository: repository, clock: FakeClock(now: now))
        let archive = try await useCase.execute(circleID: circleID, memberProfileID: me)

        #expect(archive.map(\.id) == [myExpired.id])
    }

    @Test
    func permanentEntriesNeverAppearInArchive() async throws {
        let circleID = UUID()
        let me = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let repository = InMemoryDiaryEntryRepository()
        repository.entries = [try makeEntry(circleID: circleID, authorID: me, createdAt: now.addingTimeInterval(-1_000_000), duration: .permanent)]

        let useCase = LoadMyDiaryArchiveUseCase(diaryEntryRepository: repository, clock: FakeClock(now: now))
        let archive = try await useCase.execute(circleID: circleID, memberProfileID: me)

        #expect(archive.isEmpty)
    }

    @Test
    func archiveIsOrderedNewestFirst() async throws {
        let circleID = UUID()
        let me = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let repository = InMemoryDiaryEntryRepository()
        let older = try makeEntry(circleID: circleID, authorID: me, createdAt: now.addingTimeInterval(-200 * 3600), duration: .sevenDays)
        let newer = try makeEntry(circleID: circleID, authorID: me, createdAt: now.addingTimeInterval(-100 * 3600), duration: .threeDays)
        repository.entries = [older, newer]

        let useCase = LoadMyDiaryArchiveUseCase(diaryEntryRepository: repository, clock: FakeClock(now: now))
        let archive = try await useCase.execute(circleID: circleID, memberProfileID: me)

        #expect(archive.map(\.id) == [newer.id, older.id])
    }
}
