import Testing
import Foundation
@testable import Pawlease

struct ReactToCommentUseCaseTests {
    @Test
    func selectingExistingCommentReactionRemovesIt() async throws {
        let commentID = UUID()
        let memberID = UUID()
        let repository = MockCommentReactionRepository()
        repository.reactionResult = CommentReaction(id: UUID(), commentID: commentID, memberProfileID: memberID, emoji: .paw, createdAt: Date())
        let useCase = ReactToCommentUseCase(commentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(commentID: commentID, memberProfileID: memberID, emoji: .paw)

        #expect(repository.removeReactionCallCount == 1)
        #expect(repository.saveReactionCallCount == 0)
        #expect(outcome == .removed)
    }

    @Test
    func selectingDifferentCommentReactionReplacesExistingReaction() async throws {
        let commentID = UUID()
        let memberID = UUID()
        let existingID = UUID()
        let repository = MockCommentReactionRepository()
        repository.reactionResult = CommentReaction(id: existingID, commentID: commentID, memberProfileID: memberID, emoji: .laugh, createdAt: Date())
        let useCase = ReactToCommentUseCase(commentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(commentID: commentID, memberProfileID: memberID, emoji: .comfort)

        #expect(repository.saveReactionCallCount == 1)
        #expect(repository.removeReactionCallCount == 0)
        #expect(repository.savedReactions.first?.id == existingID)
        #expect(repository.savedReactions.first?.emoji == .comfort)
        guard case .replaced(let reaction) = outcome else {
            Issue.record("Expected .replaced outcome, got \(outcome)")
            return
        }
        #expect(reaction.emoji == .comfort)
    }
}
