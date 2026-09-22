import Testing
import Foundation
@testable import Pawlease

struct LoadMomentDetailUseCaseTests {
    @Test
    func commentsAreLoadedInChronologicalOrder() async throws {
        let momentID = UUID()
        let momentRepository = MockMomentRepository()
        momentRepository.fetchMomentResult = try TestFactories.moment(day: CircleDay(value: "2026-03-15"))

        let earlier = try TestFactories.comment(momentID: momentID, body: "First", createdAt: TestFactories.date(year: 2026, month: 3, day: 15, hour: 8))
        let later = try TestFactories.comment(momentID: momentID, body: "Second", createdAt: TestFactories.date(year: 2026, month: 3, day: 15, hour: 9))

        let commentRepository = MockCommentRepository()
        // Deliberately returned out of order to prove the Use Case sorts.
        commentRepository.fetchCommentsResult = [later, earlier]

        let useCase = LoadMomentDetailUseCase(
            momentRepository: momentRepository,
            commentRepository: commentRepository,
            momentReactionRepository: MockMomentReactionRepository(),
            commentReactionRepository: MockCommentReactionRepository()
        )

        let result = try await useCase.execute(momentID: momentID)

        #expect(result.comments.map(\.body.value) == ["First", "Second"])
    }

    @Test
    func loadingDetailForAMissingMomentThrowsMomentNotFound() async {
        let momentRepository = MockMomentRepository()
        momentRepository.fetchMomentResult = nil

        let useCase = LoadMomentDetailUseCase(
            momentRepository: momentRepository,
            commentRepository: MockCommentRepository(),
            momentReactionRepository: MockMomentReactionRepository(),
            commentReactionRepository: MockCommentReactionRepository()
        )

        await #expect(throws: DomainError.momentNotFound) {
            _ = try await useCase.execute(momentID: UUID())
        }
    }
}
