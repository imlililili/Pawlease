import Testing
import Foundation
@testable import Pawlease

struct ReactToDiaryEntryUseCaseTests {
    @Test
    func firstReactionFromAMemberIsCreated() async throws {
        let entryID = UUID()
        let memberID = UUID()
        let repository = InMemoryDiaryReactionRepository()
        let useCase = ReactToDiaryEntryUseCase(diaryReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(entryID: entryID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("❤️"))

        guard case .added(let reaction) = outcome else {
            Issue.record("Expected .added outcome, got \(outcome)")
            return
        }
        #expect(reaction.emoji.value == "❤️")
        #expect(repository.reactions.count == 1)
    }

    @Test
    func sameEmojiFromTheSameMemberRemovesTheReaction() async throws {
        let entryID = UUID()
        let memberID = UUID()
        let repository = InMemoryDiaryReactionRepository()
        let existing = DiaryReaction(id: UUID(), entryID: entryID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("🌼"), createdAt: Date())
        repository.reactions = [existing]
        let useCase = ReactToDiaryEntryUseCase(diaryReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(entryID: entryID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("🌼"))

        #expect(outcome == .removed)
        #expect(repository.reactions.isEmpty)
    }

    @Test
    func differentEmojiFromTheSameMemberReplacesTheirReaction() async throws {
        let entryID = UUID()
        let memberID = UUID()
        let existingID = UUID()
        let repository = InMemoryDiaryReactionRepository()
        repository.reactions = [DiaryReaction(id: existingID, entryID: entryID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("🌼"), createdAt: Date())]
        let useCase = ReactToDiaryEntryUseCase(diaryReactionRepository: repository, clock: FakeClock(now: Date()))

        let outcome = try await useCase.execute(entryID: entryID, memberProfileID: memberID, emoji: try DiaryReactionEmoji("🔥"))

        guard case .replaced(let reaction) = outcome else {
            Issue.record("Expected .replaced outcome, got \(outcome)")
            return
        }
        #expect(reaction.id == existingID)
        #expect(reaction.emoji.value == "🔥")
        #expect(repository.reactions.count == 1)
        #expect(repository.reactions.first?.emoji.value == "🔥")
    }
}
