import Testing
import Foundation
@testable import Pawlease

struct RemoveCommentUseCaseTests {
    @Test
    func memberRemovesTheirOwnComment() async throws {
        let commentID = UUID()
        let authorID = UUID()
        let commentRepository = MockCommentRepository()
        commentRepository.fetchCommentResult = try TestFactories.comment(id: commentID, authorID: authorID)
        let useCase = RemoveCommentUseCase(commentRepository: commentRepository)

        try await useCase.execute(commentID: commentID, requestingMemberID: authorID)

        #expect(commentRepository.softDeleteCommentCallCount == 1)
        #expect(commentRepository.softDeleteCommentCapturedArguments.first?.commentID == commentID)
    }

    @Test
    func memberCannotRemoveAnotherMembersComment() async throws {
        let commentID = UUID()
        let authorID = UUID()
        let otherMemberID = UUID()
        let commentRepository = MockCommentRepository()
        commentRepository.fetchCommentResult = try TestFactories.comment(id: commentID, authorID: authorID)
        let useCase = RemoveCommentUseCase(commentRepository: commentRepository)

        await #expect(throws: DomainError.notCommentAuthor) {
            try await useCase.execute(commentID: commentID, requestingMemberID: otherMemberID)
        }

        #expect(commentRepository.softDeleteCommentCallCount == 0)
    }

    @Test
    func removingAMissingCommentThrowsCommentNotFound() async {
        let commentRepository = MockCommentRepository()
        commentRepository.fetchCommentResult = nil
        let useCase = RemoveCommentUseCase(commentRepository: commentRepository)

        await #expect(throws: DomainError.commentNotFound) {
            try await useCase.execute(commentID: UUID(), requestingMemberID: UUID())
        }

        #expect(commentRepository.softDeleteCommentCallCount == 0)
    }
}
