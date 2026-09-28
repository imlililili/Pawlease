import Testing
import Foundation
@testable import Pawlease

struct LoadDiaryDetailUseCaseTests {
    private func makeUseCase(
        entryRepository: InMemoryDiaryEntryRepository,
        commentRepository: InMemoryDiaryCommentRepository,
        reactionRepository: InMemoryDiaryReactionRepository,
        commentReactionRepository: InMemoryDiaryCommentReactionRepository
    ) -> LoadDiaryDetailUseCase {
        LoadDiaryDetailUseCase(
            diaryEntryRepository: entryRepository,
            diaryCommentRepository: commentRepository,
            diaryReactionRepository: reactionRepository,
            diaryCommentReactionRepository: commentReactionRepository
        )
    }

    @Test
    func loadingAMissingEntryThrowsDiaryEntryNotFound() async throws {
        let useCase = makeUseCase(
            entryRepository: InMemoryDiaryEntryRepository(),
            commentRepository: InMemoryDiaryCommentRepository(),
            reactionRepository: InMemoryDiaryReactionRepository(),
            commentReactionRepository: InMemoryDiaryCommentReactionRepository()
        )

        await #expect(throws: DomainError.diaryEntryNotFound) {
            try await useCase.execute(entryID: UUID())
        }
    }

    @Test
    func expirationDoesNotDeleteCommentsOrReactions() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let circleID = UUID()
        let entry = DiaryEntry(
            id: UUID(), circleID: circleID, authorProfileID: UUID(),
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("gone but not forgotten"), visibilityDuration: .oneDay,
            createdAt: now.addingTimeInterval(-25 * 3600), expiresAt: now.addingTimeInterval(-3600),
            isDeleted: false, deletedAt: nil
        )
        #expect(entry.isExpired(asOf: now))

        let comment = DiaryComment(
            id: UUID(), entryID: entry.id, authorProfileID: UUID(), authorNameSnapshot: "Ben",
            body: try CommentBody("still here"), createdAt: now.addingTimeInterval(-7200), isRemoved: false
        )
        let entryReaction = DiaryReaction(id: UUID(), entryID: entry.id, memberProfileID: UUID(), emoji: try DiaryReactionEmoji("❤️"), createdAt: now.addingTimeInterval(-7200))
        let commentReaction = DiaryCommentReaction(id: UUID(), commentID: comment.id, memberProfileID: UUID(), emoji: try DiaryReactionEmoji("🌼"), createdAt: now.addingTimeInterval(-7200))

        let entryRepository = InMemoryDiaryEntryRepository()
        entryRepository.entries = [entry]
        let commentRepository = InMemoryDiaryCommentRepository()
        commentRepository.comments = [comment]
        let reactionRepository = InMemoryDiaryReactionRepository()
        reactionRepository.reactions = [entryReaction]
        let commentReactionRepository = InMemoryDiaryCommentReactionRepository()
        commentReactionRepository.reactions = [commentReaction]

        let useCase = makeUseCase(
            entryRepository: entryRepository, commentRepository: commentRepository,
            reactionRepository: reactionRepository, commentReactionRepository: commentReactionRepository
        )
        let result = try await useCase.execute(entryID: entry.id)

        #expect(result.entry.id == entry.id)
        #expect(result.comments.map(\.id) == [comment.id])
        #expect(result.entryReactions.map(\.id) == [entryReaction.id])
        #expect(result.commentReactions.map(\.id) == [commentReaction.id])
    }
}
