import Testing
import Foundation
@testable import Pawlease

struct AddCommentUseCaseTests {
    @Test
    func memberAddsValidCommentToDailyMoment() async throws {
        let momentID = UUID()
        let author = TestFactories.member(displayName: "Ava")

        let momentRepository = MockMomentRepository()
        momentRepository.fetchMomentResult = try TestFactories.moment(day: CircleDay(value: "2026-03-15"))

        let commentRepository = MockCommentRepository()
        let useCase = AddCommentUseCase(
            commentRepository: commentRepository,
            momentRepository: momentRepository,
            clock: FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        )

        let saved = try await useCase.execute(momentID: momentID, author: author, bodyText: "Great pic!")

        #expect(momentRepository.fetchMomentCapturedIDs == [momentID])
        #expect(commentRepository.saveCommentCallCount == 1)
        #expect(commentRepository.savedComments.first?.momentID == momentID)
        #expect(commentRepository.savedComments.first?.authorProfileID == author.profileID)
        #expect(saved.body.value == "Great pic!")
    }

    @Test
    func sixtyCharacterCommentIsAccepted() async throws {
        let author = TestFactories.member()
        let momentRepository = MockMomentRepository()
        momentRepository.fetchMomentResult = try TestFactories.moment(day: CircleDay(value: "2026-03-15"))
        let commentRepository = MockCommentRepository()
        let useCase = AddCommentUseCase(
            commentRepository: commentRepository,
            momentRepository: momentRepository,
            clock: FakeClock(now: Date())
        )

        let sixty = String(repeating: "a", count: 60)
        let saved = try await useCase.execute(momentID: UUID(), author: author, bodyText: sixty)

        #expect(saved.body.value.count == 60)
        #expect(commentRepository.saveCommentCallCount == 1)
    }

    @Test
    func sixtyOneCharacterCommentIsRejectedBeforeRepositoryWrite() async {
        let author = TestFactories.member()
        let momentRepository = MockMomentRepository()
        let commentRepository = MockCommentRepository()
        let useCase = AddCommentUseCase(
            commentRepository: commentRepository,
            momentRepository: momentRepository,
            clock: FakeClock(now: Date())
        )

        let tooLong = String(repeating: "a", count: 61)

        await #expect(throws: DomainValidationError.commentTooLong) {
            _ = try await useCase.execute(momentID: UUID(), author: author, bodyText: tooLong)
        }

        #expect(commentRepository.saveCommentCallCount == 0)
        #expect(momentRepository.fetchMomentCallCount == 0)
    }

    @Test
    func emptyCommentIsRejectedBeforeRepositoryWrite() async {
        let author = TestFactories.member()
        let momentRepository = MockMomentRepository()
        let commentRepository = MockCommentRepository()
        let useCase = AddCommentUseCase(
            commentRepository: commentRepository,
            momentRepository: momentRepository,
            clock: FakeClock(now: Date())
        )

        await #expect(throws: DomainValidationError.commentEmpty) {
            _ = try await useCase.execute(momentID: UUID(), author: author, bodyText: "   ")
        }

        #expect(commentRepository.saveCommentCallCount == 0)
    }

    @Test
    func targetMomentMustExistBeforeCommentIsSaved() async {
        let author = TestFactories.member()
        let momentRepository = MockMomentRepository()
        momentRepository.fetchMomentResult = nil
        let commentRepository = MockCommentRepository()
        let useCase = AddCommentUseCase(
            commentRepository: commentRepository,
            momentRepository: momentRepository,
            clock: FakeClock(now: Date())
        )

        await #expect(throws: DomainError.momentNotFound) {
            _ = try await useCase.execute(momentID: UUID(), author: author, bodyText: "Hello")
        }

        #expect(commentRepository.saveCommentCallCount == 0)
    }

    @Test
    func repositoryFailureIsReturnedWhenAddingComment() async {
        struct StubRepositoryError: Error, Equatable {}

        let author = TestFactories.member()
        let momentRepository = MockMomentRepository()
        momentRepository.fetchMomentResult = try? TestFactories.moment(day: CircleDay(value: "2026-03-15"))
        let commentRepository = MockCommentRepository()
        commentRepository.saveCommentError = StubRepositoryError()
        let useCase = AddCommentUseCase(
            commentRepository: commentRepository,
            momentRepository: momentRepository,
            clock: FakeClock(now: Date())
        )

        await #expect(throws: StubRepositoryError.self) {
            _ = try await useCase.execute(momentID: UUID(), author: author, bodyText: "Hello")
        }

        #expect(commentRepository.saveCommentCallCount == 1)
    }
}
