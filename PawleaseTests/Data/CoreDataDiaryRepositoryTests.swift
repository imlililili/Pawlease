import Testing
import Foundation
@testable import Pawlease

/// Integration tests against the real, in-memory Core Data stack for the
/// Circle Diary entities — not mock-based, and not counted toward the
/// minimum mock-based unit test requirement. These prove the `.xcdatamodel`
/// schema, mappers, and repositories actually work together end to end,
/// including the `isSoftDeleted` Core Data attribute (renamed from
/// `isDeleted` to avoid colliding with `NSManagedObject.isDeleted`).
struct CoreDataDiaryRepositoryTests {
    private func makeCircle(persistence: PersistenceController) async throws -> FriendCircle {
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let circle = FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        return try await circleRepo.saveCircle(circle)
    }

    @Test
    func savingAndLoadingAnEntryWithCommentsAndReactionsRoundTripsThroughCoreData() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circle = try await makeCircle(persistence: persistence)

        let entryRepo = CoreDataDiaryEntryRepository(container: persistence.container)
        let commentRepo = CoreDataDiaryCommentRepository(container: persistence.container)
        let reactionRepo = CoreDataDiaryReactionRepository(container: persistence.container)
        let commentReactionRepo = CoreDataDiaryCommentReactionRepository(container: persistence.container)

        let authorID = UUID()
        let entry = DiaryEntry(
            id: UUID(), circleID: circle.id, authorProfileID: authorID,
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("A permanent thought worth keeping."), visibilityDuration: .permanent,
            createdAt: Date(), expiresAt: nil, isDeleted: false, deletedAt: nil
        )
        let savedEntry = try await entryRepo.saveEntry(entry)
        #expect(savedEntry.body.value == "A permanent thought worth keeping.")

        let commentAuthorID = UUID()
        let comment = DiaryComment(
            id: UUID(), entryID: savedEntry.id, authorProfileID: commentAuthorID, authorNameSnapshot: "Noah",
            body: try CommentBody("Love this!"), createdAt: Date(), isRemoved: false
        )
        let savedComment = try await commentRepo.saveComment(comment)

        try await reactionRepo.saveReaction(DiaryReaction(
            id: UUID(), entryID: savedEntry.id, memberProfileID: UUID(), emoji: try DiaryReactionEmoji("❤️"), createdAt: Date()
        ))
        try await commentReactionRepo.saveReaction(DiaryCommentReaction(
            id: UUID(), commentID: savedComment.id, memberProfileID: UUID(), emoji: try DiaryReactionEmoji("🌼"), createdAt: Date()
        ))

        let fetchedEntry = try await entryRepo.fetchEntry(entryID: savedEntry.id)
        #expect(fetchedEntry?.id == savedEntry.id)
        #expect(fetchedEntry?.body.value == "A permanent thought worth keeping.")

        let fetchedComments = try await commentRepo.fetchComments(entryID: savedEntry.id)
        #expect(fetchedComments.count == 1)
        #expect(fetchedComments.first?.body.value == "Love this!")

        let fetchedReactions = try await reactionRepo.fetchReactions(entryID: savedEntry.id)
        #expect(fetchedReactions.count == 1)
        #expect(fetchedReactions.first?.emoji.value == "❤️")

        let fetchedCommentReactions = try await commentReactionRepo.fetchReactions(commentID: savedComment.id)
        #expect(fetchedCommentReactions.count == 1)
        #expect(fetchedCommentReactions.first?.emoji.value == "🌼")
    }

    @Test
    func softDeletionMarksTheEntryDeletedWithoutRemovingItFromTheStore() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circle = try await makeCircle(persistence: persistence)
        let entryRepo = CoreDataDiaryEntryRepository(container: persistence.container)

        let authorID = UUID()
        let entry = DiaryEntry(
            id: UUID(), circleID: circle.id, authorProfileID: authorID,
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("Soon to be deleted."), visibilityDuration: .permanent,
            createdAt: Date(), expiresAt: nil, isDeleted: false, deletedAt: nil
        )
        let saved = try await entryRepo.saveEntry(entry)

        let deletedAt = Date(timeIntervalSince1970: 1_700_000_000)
        try await entryRepo.softDeleteEntry(entryID: saved.id, requestingProfileID: authorID, deletedAt: deletedAt)

        let fetched = try await entryRepo.fetchEntry(entryID: saved.id)
        #expect(fetched?.isDeleted == true)
        #expect(fetched?.deletedAt == deletedAt)
        #expect(fetched?.id == saved.id)
        #expect(fetched?.body.value == "Soon to be deleted.")
    }

    @Test
    func softDeletionByAnyoneOtherThanTheAuthorIsRejectedAtTheRepositoryLayer() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circle = try await makeCircle(persistence: persistence)
        let entryRepo = CoreDataDiaryEntryRepository(container: persistence.container)

        let authorID = UUID()
        let entry = DiaryEntry(
            id: UUID(), circleID: circle.id, authorProfileID: authorID,
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("Not yours to delete."), visibilityDuration: .permanent,
            createdAt: Date(), expiresAt: nil, isDeleted: false, deletedAt: nil
        )
        let saved = try await entryRepo.saveEntry(entry)

        await #expect(throws: DomainError.notDiaryEntryAuthor) {
            try await entryRepo.softDeleteEntry(entryID: saved.id, requestingProfileID: UUID(), deletedAt: Date())
        }
        let fetched = try await entryRepo.fetchEntry(entryID: saved.id)
        #expect(fetched?.isDeleted == false)
    }

    @Test
    func expiredEntriesRemainPersistedAndAccessibleToArchive() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circle = try await makeCircle(persistence: persistence)
        let entryRepo = CoreDataDiaryEntryRepository(container: persistence.container)

        let authorID = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let createdAt = now.addingTimeInterval(-25 * 3600)
        let entry = DiaryEntry(
            id: UUID(), circleID: circle.id, authorProfileID: authorID,
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("This expired a while ago."), visibilityDuration: .oneDay,
            createdAt: createdAt, expiresAt: DiaryVisibilityDuration.oneDay.expiresAt(from: createdAt),
            isDeleted: false, deletedAt: nil
        )
        try await entryRepo.saveEntry(entry)

        let archiveUseCase = LoadMyDiaryArchiveUseCase(diaryEntryRepository: entryRepo, clock: FakeClock(now: now))
        let archive = try await archiveUseCase.execute(circleID: circle.id, memberProfileID: authorID)

        #expect(archive.count == 1)
        #expect(archive.first?.id == entry.id)
        #expect(archive.first?.isExpired(asOf: now) == true)

        // Still directly fetchable from the store — expiry never deletes the row.
        let fetched = try await entryRepo.fetchEntry(entryID: entry.id)
        #expect(fetched != nil)
        #expect(fetched?.isDeleted == false)
    }
}
