import Testing
import Foundation
@testable import Pawlease

struct AddDiaryCommentUseCaseTests {
    @Test
    func commentingOnAnExistingEntrySavesTheComment() async throws {
        let circleID = UUID()
        let entryRepository = InMemoryDiaryEntryRepository()
        let entry = DiaryEntry(
            id: UUID(), circleID: circleID, authorProfileID: UUID(),
            authorNameSnapshot: "Ava", authorAvatarSnapshot: "🐼",
            body: try DiaryEntryBody("a thought"), visibilityDuration: .permanent,
            createdAt: Date(), expiresAt: nil, isDeleted: false, deletedAt: nil
        )
        entryRepository.entries = [entry]
        let commentRepository = InMemoryDiaryCommentRepository()
        let author = TestFactories.member(circleID: circleID, displayName: "Ben")
        let useCase = AddDiaryCommentUseCase(diaryCommentRepository: commentRepository, diaryEntryRepository: entryRepository, clock: FakeClock(now: Date()))

        let comment = try await useCase.execute(entryID: entry.id, author: author, bodyText: "Love this!")

        #expect(comment.entryID == entry.id)
        #expect(comment.authorProfileID == author.profileID)
        #expect(commentRepository.comments.count == 1)
    }

    @Test
    func commentingOnAMissingEntryThrowsDiaryEntryNotFound() async throws {
        let entryRepository = InMemoryDiaryEntryRepository()
        let commentRepository = InMemoryDiaryCommentRepository()
        let author = TestFactories.member()
        let useCase = AddDiaryCommentUseCase(diaryCommentRepository: commentRepository, diaryEntryRepository: entryRepository, clock: FakeClock(now: Date()))

        await #expect(throws: DomainError.diaryEntryNotFound) {
            try await useCase.execute(entryID: UUID(), author: author, bodyText: "Hello")
        }
    }
}
