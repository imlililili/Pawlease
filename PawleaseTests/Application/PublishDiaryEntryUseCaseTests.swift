import Testing
import Foundation
@testable import Pawlease

struct PublishDiaryEntryUseCaseTests {
    @Test
    func publishingATimedEntryComputesItsExpiryFromTheInjectedClock() async throws {
        let circleID = UUID()
        let author = TestFactories.member(circleID: circleID, displayName: "Ava")
        let repository = InMemoryDiaryEntryRepository()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let useCase = PublishDiaryEntryUseCase(diaryEntryRepository: repository, clock: FakeClock(now: now))

        let entry = try await useCase.execute(
            circleID: circleID, author: author, bodyText: "Had a great walk today!", visibilityDuration: .oneDay
        )

        #expect(entry.circleID == circleID)
        #expect(entry.authorProfileID == author.profileID)
        #expect(entry.body.value == "Had a great walk today!")
        #expect(entry.createdAt == now)
        #expect(entry.expiresAt == now.addingTimeInterval(24 * 3600))
        #expect(repository.entries.count == 1)
    }

    @Test
    func publishingAPermanentEntryLeavesExpiresAtNil() async throws {
        let circleID = UUID()
        let author = TestFactories.member(circleID: circleID)
        let repository = InMemoryDiaryEntryRepository()
        let useCase = PublishDiaryEntryUseCase(diaryEntryRepository: repository, clock: FakeClock(now: Date()))

        let entry = try await useCase.execute(
            circleID: circleID, author: author, bodyText: "This one stays forever.", visibilityDuration: .permanent
        )

        #expect(entry.expiresAt == nil)
    }

    @Test
    func whitespaceOnlyBodyTextIsRejectedBeforeSaving() async throws {
        let circleID = UUID()
        let author = TestFactories.member(circleID: circleID)
        let repository = InMemoryDiaryEntryRepository()
        let useCase = PublishDiaryEntryUseCase(diaryEntryRepository: repository, clock: FakeClock(now: Date()))

        await #expect(throws: DomainValidationError.diaryBodyEmpty) {
            try await useCase.execute(circleID: circleID, author: author, bodyText: "   ", visibilityDuration: .oneDay)
        }
        #expect(repository.entries.isEmpty)
    }
}
