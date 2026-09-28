import Testing
import Foundation
@testable import Pawlease

/// Proves a Circle Diary entry never changes a Daily Moment's contributor
/// count or the pet's survival status: `CalculateDailyCareStatusUseCase`
/// takes only `[DailyMoment]` and never reads any Diary type or repository,
/// so publishing a Diary entry has no path to influence its result.
struct DiaryEntryDoesNotAffectDailyCareTests {
    @Test
    func publishingADiaryEntryDoesNotChangeContributorCountOrSurvival() async throws {
        let circleID = UUID()
        let author = TestFactories.member(circleID: circleID)
        let day = CircleDay(value: "2026-03-15")
        let moment = try TestFactories.moment(circleID: circleID, authorID: author.profileID, day: day)

        let statusBefore = CalculateDailyCareStatusUseCase().execute(moments: [moment])
        #expect(statusBefore.contributorCount == 1)
        #expect(statusBefore.hasSurvived == false)

        let diaryRepository = InMemoryDiaryEntryRepository()
        let publishDiaryEntry = PublishDiaryEntryUseCase(diaryEntryRepository: diaryRepository, clock: FakeClock(now: Date()))
        try await publishDiaryEntry.execute(
            circleID: circleID, author: author, bodyText: "Just a text-only thought, no photo here.",
            visibilityDuration: .oneDay
        )
        #expect(diaryRepository.entries.count == 1)

        let statusAfter = CalculateDailyCareStatusUseCase().execute(moments: [moment])
        #expect(statusAfter.contributorCount == statusBefore.contributorCount)
        #expect(statusAfter.hasSurvived == statusBefore.hasSurvived)
    }

    @Test
    func publishingMultipleDiaryEntriesFromDistinctMembersStillRequiresTwoDistinctMomentContributors() async throws {
        let circleID = UUID()
        let day = CircleDay(value: "2026-03-15")
        let onlyMomentAuthor = UUID()
        let moment = try TestFactories.moment(circleID: circleID, authorID: onlyMomentAuthor, day: day)

        let diaryRepository = InMemoryDiaryEntryRepository()
        let publishDiaryEntry = PublishDiaryEntryUseCase(diaryEntryRepository: diaryRepository, clock: FakeClock(now: Date()))
        for _ in 0..<3 {
            let diaryAuthor = TestFactories.member(circleID: circleID)
            try await publishDiaryEntry.execute(
                circleID: circleID, author: diaryAuthor, bodyText: "Another diary voice.", visibilityDuration: .permanent
            )
        }
        #expect(diaryRepository.entries.count == 3)

        let status = CalculateDailyCareStatusUseCase().execute(moments: [moment])
        #expect(status.contributorCount == 1)
        #expect(status.hasSurvived == false)
    }
}
