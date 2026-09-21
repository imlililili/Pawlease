import Testing
import Foundation
@testable import Pawlease

struct CalculateDailyCareStatusUseCaseTests {
    @Test func duplicatePostsFromSameMemberCountAsOneContributor() throws {
        let authorID = UUID()
        let day = CircleDay(value: "2026-03-15")
        let moment1 = try TestFactories.moment(authorID: authorID, day: day, caption: "First")
        let moment2 = try TestFactories.moment(authorID: authorID, day: day, caption: "Second")

        let status = CalculateDailyCareStatusUseCase().execute(moments: [moment1, moment2])

        #expect(status.contributorCount == 1)
        #expect(status.hasSurvived == false)
    }

    @Test func twoDistinctMembersProduceASurvivedDay() throws {
        let day = CircleDay(value: "2026-03-15")
        let moment1 = try TestFactories.moment(authorID: UUID(), day: day, caption: "First")
        let moment2 = try TestFactories.moment(authorID: UUID(), day: day, caption: "Second")

        let status = CalculateDailyCareStatusUseCase().execute(moments: [moment1, moment2])

        #expect(status.contributorCount == 2)
        #expect(status.hasSurvived)
    }
}
