import Foundation

/// Loads the shared Circle Diary feed: every entry for this Circle that is
/// neither soft-deleted nor expired, newest first, each paired with its
/// comment count and reactions so the feed row can show both without a
/// separate round trip per entry. Expiry is recalculated here from each
/// entry's own `createdAt`/`expiresAt` against the injected clock — never a
/// stored flag.
struct LoadActiveDiaryFeedUseCase: Sendable {
    struct FeedItem: Sendable, Equatable {
        let entry: DiaryEntry
        let commentCount: Int
        let reactions: [DiaryReaction]
    }

    let diaryEntryRepository: DiaryEntryRepository
    let diaryCommentRepository: DiaryCommentRepository
    let diaryReactionRepository: DiaryReactionRepository
    let clock: ClockProviding

    func execute(circleID: UUID) async throws -> [FeedItem] {
        let now = clock.now
        let activeEntries = try await diaryEntryRepository
            .fetchEntries(circleID: circleID)
            .filter { $0.circleID == circleID && $0.isActive(asOf: now) }
            .sorted { $0.createdAt > $1.createdAt }

        var items: [FeedItem] = []
        for entry in activeEntries {
            let comments = try await diaryCommentRepository.fetchComments(entryID: entry.id)
            let reactions = try await diaryReactionRepository.fetchReactions(entryID: entry.id)
            items.append(FeedItem(
                entry: entry,
                commentCount: comments.filter { !$0.isRemoved }.count,
                reactions: reactions
            ))
        }
        return items
    }
}
