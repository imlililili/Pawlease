import Foundation

/// Publishes one new Circle Diary entry. Text-only — no photo, no mood, no
/// attachment — and never touches `MomentRepository`/`PetRepository`: a
/// Diary entry can never affect contributor count, survival, streak, or
/// pet growth.
struct PublishDiaryEntryUseCase: Sendable {
    let diaryEntryRepository: DiaryEntryRepository
    let clock: ClockProviding

    @discardableResult
    func execute(
        circleID: UUID,
        author: CircleMember,
        bodyText: String,
        visibilityDuration: DiaryVisibilityDuration
    ) async throws -> DiaryEntry {
        let body = try DiaryEntryBody(bodyText)
        let createdAt = clock.now

        let entry = DiaryEntry(
            id: UUID(),
            circleID: circleID,
            authorProfileID: author.profileID,
            authorNameSnapshot: author.displayName,
            authorAvatarSnapshot: author.avatarEmoji,
            body: body,
            visibilityDuration: visibilityDuration,
            createdAt: createdAt,
            expiresAt: visibilityDuration.expiresAt(from: createdAt),
            isDeleted: false,
            deletedAt: nil
        )
        return try await diaryEntryRepository.saveEntry(entry)
    }
}
