import Foundation

/// Publishes one new single-level comment on a `DailyMoment`. Comments and
/// reactions never affect contributor count, survival, streak, or growth —
/// this Use Case only touches `CommentRepository`.
struct AddCommentUseCase: Sendable {
    let commentRepository: CommentRepository
    let momentRepository: MomentRepository
    let clock: ClockProviding

    @discardableResult
    func execute(momentID: UUID, author: CircleMember, bodyText: String) async throws -> MomentComment {
        let body = try CommentBody(bodyText)

        guard try await momentRepository.fetchMoment(id: momentID) != nil else {
            throw DomainError.momentNotFound
        }

        let comment = MomentComment(
            id: UUID(),
            momentID: momentID,
            authorProfileID: author.profileID,
            authorNameSnapshot: author.displayName,
            body: body,
            createdAt: clock.now,
            isRemoved: false
        )
        return try await commentRepository.saveComment(comment)
    }
}
