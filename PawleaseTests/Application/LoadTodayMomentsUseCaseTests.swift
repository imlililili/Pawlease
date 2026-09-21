import Testing
import Foundation
@testable import Pawlease

struct LoadTodayMomentsUseCaseTests {
    @Test func memberWhoHasNotPostedCannotReadFriendsMoments() async throws {
        let momentRepo = InMemoryMomentRepository()
        let circleID = UUID()
        let day = CircleDay(value: "2026-03-15")
        let requester = UUID()
        momentRepo.moments = [try TestFactories.moment(circleID: circleID, authorID: UUID(), day: day)]

        let useCase = LoadTodayMomentsUseCase(momentRepository: momentRepo)

        await #expect(throws: DomainError.feedLocked) {
            _ = try await useCase.execute(circleID: circleID, requestingProfileID: requester, day: day)
        }
    }

    @Test func memberWhoHasPostedCanReadFriendsMoments() async throws {
        let momentRepo = InMemoryMomentRepository()
        let circleID = UUID()
        let day = CircleDay(value: "2026-03-15")
        let requester = UUID()
        momentRepo.moments = [
            try TestFactories.moment(circleID: circleID, authorID: requester, day: day),
            try TestFactories.moment(circleID: circleID, authorID: UUID(), day: day)
        ]

        let useCase = LoadTodayMomentsUseCase(momentRepository: momentRepo)
        let moments = try await useCase.execute(circleID: circleID, requestingProfileID: requester, day: day)

        #expect(moments.count == 2)
    }
}
