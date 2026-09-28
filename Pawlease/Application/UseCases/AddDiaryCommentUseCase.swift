import Foundation

/// Publishes one new single-level comment on a `DiaryEntry`. Mirrors
/// `AddCommentUseCase`; never touches `MomentRepository`/`PetRepository`.
struct AddDiaryCommentUseCase: Sendable {
    let diaryCommentRepository: DiaryCommentRepository
    let diaryEntryRepository: DiaryEntryRepository
    let clock: ClockProviding

    @discardableResult
    func execute(entryID: UUID, author: CircleMember, bodyText: String) async throws -> DiaryComment {
        let body = try CommentBody(bodyText)

        guard try await diaryEntryRepository.fetchEntry(entryID: entryID) != nil else {
            throw DomainError.diaryEntryNotFound
        }

        let comment = DiaryComment(
            id: UUID(),
            entryID: entryID,
            authorProfileID: author.profileID,
            authorNameSnapshot: author.displayName,
            body: body,
            createdAt: clock.now,
            isRemoved: false
        )
        return try await diaryCommentRepository.saveComment(comment)
    }
}
