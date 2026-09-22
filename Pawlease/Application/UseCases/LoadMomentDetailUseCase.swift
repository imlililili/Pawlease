import Foundation

/// Assembles everything the Post Detail screen needs: the moment itself, its
/// comments in chronological order, and every reaction on the moment and its
/// comments. Pure orchestration — grouping reactions per member for display
/// is the Presentation layer's job (see `PostDetailViewState`).
struct LoadMomentDetailUseCase: Sendable {
    struct Result: Sendable, Equatable {
        let moment: DailyMoment
        let comments: [MomentComment]
        let momentReactions: [MomentReaction]
        let commentReactions: [CommentReaction]
    }

    let momentRepository: MomentRepository
    let commentRepository: CommentRepository
    let momentReactionRepository: MomentReactionRepository
    let commentReactionRepository: CommentReactionRepository

    func execute(momentID: UUID) async throws -> Result {
        guard let moment = try await momentRepository.fetchMoment(id: momentID) else {
            throw DomainError.momentNotFound
        }

        let comments = try await commentRepository
            .fetchComments(momentID: momentID)
            .sorted { $0.createdAt < $1.createdAt }

        let momentReactions = try await momentReactionRepository.fetchReactions(momentID: momentID)

        var commentReactions: [CommentReaction] = []
        for comment in comments {
            commentReactions += try await commentReactionRepository.fetchReactions(commentID: comment.id)
        }

        return Result(
            moment: moment,
            comments: comments,
            momentReactions: momentReactions,
            commentReactions: commentReactions
        )
    }
}
