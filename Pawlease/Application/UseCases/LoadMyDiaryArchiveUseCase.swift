import Foundation

/// Loads the current member's private Archive: their own Diary entries that
/// have expired out of the shared feed (but were never deleted). A
/// permanent entry never appears here, since it never expires. Comments and
/// reactions on an archived entry are never removed — Archive only changes
/// *visibility* in the shared feed, never the underlying record.
struct LoadMyDiaryArchiveUseCase: Sendable {
    let diaryEntryRepository: DiaryEntryRepository
    let clock: ClockProviding

    func execute(circleID: UUID, memberProfileID: UUID) async throws -> [DiaryEntry] {
        let now = clock.now
        return try await diaryEntryRepository
            .fetchEntries(circleID: circleID)
            .filter { $0.authorProfileID == memberProfileID && !$0.isDeleted && $0.isExpired(asOf: now) }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
