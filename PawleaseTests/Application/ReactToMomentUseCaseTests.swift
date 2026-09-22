import Testing
import Foundation
@testable import Pawlease

struct ReactToMomentUseCaseTests {
    @Test
    func selectingNewReactionOnMomentCreatesIt() async throws {
        let momentID = UUID()
        let memberID = UUID()
        let repository = MockMomentReactionRepository()
        repository.reactionResult = nil
        let useCase = ReactToMomentUseCase(momentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(momentID: momentID, memberProfileID: memberID, emoji: .heart)

        #expect(repository.saveReactionCallCount == 1)
        #expect(repository.removeReactionCallCount == 0)
        #expect(repository.savedReactions.first?.emoji == .heart)
        guard case .added(let reaction) = outcome else {
            Issue.record("Expected .added outcome, got \(outcome)")
            return
        }
        #expect(reaction.emoji == .heart)
    }

    @Test
    func selectingExistingReactionRemovesIt() async throws {
        let momentID = UUID()
        let memberID = UUID()
        let repository = MockMomentReactionRepository()
        repository.reactionResult = MomentReaction(id: UUID(), momentID: momentID, memberProfileID: memberID, emoji: .heart, createdAt: Date())
        let useCase = ReactToMomentUseCase(momentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(momentID: momentID, memberProfileID: memberID, emoji: .heart)

        #expect(repository.removeReactionCallCount == 1)
        #expect(repository.saveReactionCallCount == 0)
        #expect(outcome == .removed)
    }

    @Test
    func selectingDifferentReactionReplacesExistingReaction() async throws {
        let momentID = UUID()
        let memberID = UUID()
        let existingID = UUID()
        let repository = MockMomentReactionRepository()
        repository.reactionResult = MomentReaction(id: existingID, momentID: momentID, memberProfileID: memberID, emoji: .heart, createdAt: Date())
        let useCase = ReactToMomentUseCase(momentReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(momentID: momentID, memberProfileID: memberID, emoji: .fire)

        #expect(repository.saveReactionCallCount == 1)
        #expect(repository.removeReactionCallCount == 0)
        // Only one reaction row remains semantically valid: the same id is
        // reused rather than a second row being created for this member.
        #expect(repository.savedReactions.first?.id == existingID)
        #expect(repository.savedReactions.first?.emoji == .fire)
        guard case .replaced(let reaction) = outcome else {
            Issue.record("Expected .replaced outcome, got \(outcome)")
            return
        }
        #expect(reaction.emoji == .fire)
    }
}
