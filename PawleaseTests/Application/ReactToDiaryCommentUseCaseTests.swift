import Testing
import Foundation
@testable import Pawlease

struct ReactToDiaryCommentUseCaseTests {
    @Test
    func firstReactionFromAMemberIsCreated() async throws {
        let commentID = UUID()
        let memberID = UUID()
        let repository = InMemoryDiaryCommentReactionRepository()
        let useCase = ReactToDiaryCommentUseCase(diaryCommentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(commentID: commentID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("😂"))

        guard case .added(let reaction) = outcome else {
            Issue.record("Expected .added outcome, got \(outcome)")
            return
        }
        #expect(reaction.emoji.value == "😂")
    }

    @Test
    func sameEmojiFromTheSameMemberRemovesTheReaction() async throws {
        let commentID = UUID()
        let memberID = UUID()
        let repository = InMemoryDiaryCommentReactionRepository()
        repository.reactions = [DiaryCommentReaction(id: UUID(), commentID: commentID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("😂"), createdAt: Date())]
        let useCase = ReactToDiaryCommentUseCase(diaryCommentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(commentID: commentID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("😂"))

        #expect(outcome == .removed)
        #expect(repository.reactions.isEmpty)
    }

    @Test
    func differentEmojiFromTheSameMemberReplacesTheirReaction() async throws {
        let commentID = UUID()
        let memberID = UUID()
        let existingID = UUID()
        let repository = InMemoryDiaryCommentReactionRepository()
        repository.reactions = [DiaryCommentReaction(id: existingID, commentID: commentID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("😂"), createdAt: Date())]
        let useCase = ReactToDiaryCommentUseCase(diaryCommentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(commentID: commentID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("🥲"))

        guard case .replaced(let reaction) = outcome else {
            Issue.record("Expected .replaced outcome, got \(outcome)")
            return
        }
        #expect(reaction.id == existingID)
        #expect(reaction.emoji.value == "🥲")
    }
}
