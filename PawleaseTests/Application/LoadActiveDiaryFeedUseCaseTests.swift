import Testing
import Foundation
@testable import Pawlease

struct LoadActiveDiaryFeedUseCaseTests {
    private func makeUseCase(
        entryRepository: InMemoryDiaryEntryRepository,
        commentRepository: InMemoryDiaryCommentRepository = InMemoryDiaryCommentRepository(),
        reactionRepository: InMemoryDiaryReactionRepository = InMemoryDiaryReactionRepository(),
        now: Date
    ) -> LoadActiveDiaryFeedUseCase {
        LoadActiveDiaryFeedUseCase(
            diaryEntryRepository: entryRepository,
            diaryCommentRepository: commentRepository,
            diaryReactionRepository: reactionRepository,
            clock: FakeClock(now: now)
        )
    }

    private func makeEntry(
        circleID: UUID,
        createdAt: Date,
        duration: DiaryVisibilityDuration = .permanent,
        isDeleted: Bool = false
    ) throws -> DiaryEntry {
        DiaryEntry(
            id: UUID(), circleID: circleID, authorProfileID: UUID(),
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("hello"), visibilityDuration: duration,
            createdAt: createdAt, expiresAt: duration.expiresAt(from: createdAt),
            isDeleted: isDeleted, deletedAt: isDeleted ? createdAt : nil
        )
    }

    @Test
    func activeFeedExcludesExpiredDeletedAndOtherCircleEntries() async throws {
        let circleID = UUID()
        let otherCircleID = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let repository = InMemoryDiaryEntryRepository()

        let active = try makeEntry(circleID: circleID, createdAt: now.addingTimeInterval(-3600))
        let expired = try makeEntry(circleID: circleID, createdAt: now.addingTimeInterval(-25 * 3600), duration: .oneDay)
        let deleted = try makeEntry(circleID: circleID, createdAt: now.addingTimeInterval(-1800), isDeleted: true)
        let otherCircle = try makeEntry(circleID: otherCircleID, createdAt: now.addingTimeInterval(-1800))
        repository.entries = [active, expired, deleted, otherCircle]

        let useCase = makeUseCase(entryRepository: repository, now: now)
        let feed = try await useCase.execute(circleID: circleID)

        #expect(feed.map(\.entry.id) == [active.id])
    }

    @Test
    func activeFeedIsOrderedNewestFirst() async throws {
        let circleID = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let repository = InMemoryDiaryEntryRepository()

        let oldest = try makeEntry(circleID: circleID, createdAt: now.addingTimeInterval(-7200))
        let middle = try makeEntry(circleID: circleID, createdAt: now.addingTimeInterval(-3600))
        let newest = try makeEntry(circleID: circleID, createdAt: now)
        repository.entries = [oldest, newest, middle]

        let useCase = makeUseCase(entryRepository: repository, now: now)
        let feed = try await useCase.execute(circleID: circleID)

        #expect(feed.map(\.entry.id) == [newest.id, middle.id, oldest.id])
    }

    @Test
    func feedItemsIncludeCommentCountAndReactions() async throws {
        let circleID = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let entryRepository = InMemoryDiaryEntryRepository()
        let entry = try makeEntry(circleID: circleID, createdAt: now)
        entryRepository.entries = [entry]

        let commentRepository = InMemoryDiaryCommentRepository()
        commentRepository.comments = [
            DiaryComment(id: UUID(), entryID: entry.id, authorProfileID: UUID(), authorNameSnapshot: "Ben", body: try CommentBody("Cute!"), createdAt: now, isRemoved: false),
            DiaryComment(id: UUID(), entryID: entry.id, authorProfileID: UUID(), authorNameSnapshot: "Cy", body: try CommentBody("Removed"), createdAt: now, isRemoved: true)
        ]

        let reactionRepository = InMemoryDiaryReactionRepository()
        reactionRepository.reactions = [
            DiaryReaction(id: UUID(), entryID: entry.id, memberProfileID: UUID(), emoji: try DiaryReactionEmoji("❤️"), createdAt: now)
        ]

        let useCase = makeUseCase(entryRepository: entryRepository, commentRepository: commentRepository, reactionRepository: reactionRepository, now: now)
        let feed = try await useCase.execute(circleID: circleID)

        #expect(feed.count == 1)
        #expect(feed[0].commentCount == 1)
        #expect(feed[0].reactions.count == 1)
    }
}
