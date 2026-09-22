import Foundation

/// Presentation-ready, pre-formatted state for the Post Detail screen,
/// derived once from a `LoadMomentDetailUseCase.Result` so the View stays
/// free of grouping/formatting logic.
struct PostDetailViewState: Equatable {
    struct ReactionSummaryItem: Equatable, Identifiable {
        let emoji: ReactionEmoji
        let count: Int
        var id: ReactionEmoji { emoji }
    }

    struct CommentItem: Equatable, Identifiable {
        let id: UUID
        let authorName: String
        let displayBody: String
        let createdAt: Date
        let isOwnComment: Bool
        let isRemoved: Bool
        let reactionSummary: [ReactionSummaryItem]
        let currentMemberReaction: ReactionEmoji?
    }

    let authorName: String
    let caption: String
    let moodEmoji: String?
    let createdAt: Date
    let imageData: Data
    let momentReactionSummary: [ReactionSummaryItem]
    let currentMemberMomentReaction: ReactionEmoji?
    let comments: [CommentItem]

    init(result: LoadMomentDetailUseCase.Result, currentMemberProfileID: UUID) {
        authorName = result.moment.authorNameSnapshot
        caption = result.moment.caption.value
        moodEmoji = result.moment.moodEmoji
        createdAt = result.moment.createdAt
        imageData = result.moment.photo.imageData
        momentReactionSummary = Self.summarize(result.momentReactions.map(\.emoji))
        currentMemberMomentReaction = result.momentReactions
            .first { $0.memberProfileID == currentMemberProfileID }?.emoji

        comments = result.comments.map { comment in
            let reactionsForComment = result.commentReactions.filter { $0.commentID == comment.id }
            return CommentItem(
                id: comment.id,
                authorName: comment.authorNameSnapshot,
                displayBody: comment.isRemoved ? "Comment removed" : comment.body.value,
                createdAt: comment.createdAt,
                isOwnComment: comment.authorProfileID == currentMemberProfileID,
                isRemoved: comment.isRemoved,
                reactionSummary: Self.summarize(reactionsForComment.map(\.emoji)),
                currentMemberReaction: reactionsForComment
                    .first { $0.memberProfileID == currentMemberProfileID }?.emoji
            )
        }
    }

    private static func summarize(_ emojis: [ReactionEmoji]) -> [ReactionSummaryItem] {
        var counts: [ReactionEmoji: Int] = [:]
        for emoji in emojis {
            counts[emoji, default: 0] += 1
        }
        return ReactionEmoji.allCases.compactMap { emoji in
            guard let count = counts[emoji], count > 0 else { return nil }
            return ReactionSummaryItem(emoji: emoji, count: count)
        }
    }
}
