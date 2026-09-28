import Foundation

/// Presentation-ready, pre-formatted state for the Diary Entry Detail
/// screen, derived once from a `LoadDiaryDetailUseCase.Result` so the View
/// stays free of grouping/formatting logic.
struct DiaryEntryDetailViewState: Equatable {
    struct ReactionSummaryItem: Equatable, Identifiable {
        let emoji: String
        let count: Int
        var id: String { emoji }
    }

    struct CommentItem: Equatable, Identifiable {
        let id: UUID
        let authorName: String
        let displayBody: String
        let createdAt: Date
        let isOwnComment: Bool
        let isRemoved: Bool
        let reactionSummary: [ReactionSummaryItem]
        let currentMemberReactionEmoji: String?
    }

    let authorName: String
    let authorAvatarEmoji: String
    let bodyText: String
    let createdAt: Date
    let isPermanent: Bool
    let expirationLabel: String?
    let isOwnEntry: Bool
    let entryReactionSummary: [ReactionSummaryItem]
    let currentMemberEntryReactionEmoji: String?
    let comments: [CommentItem]

    init(result: LoadDiaryDetailUseCase.Result, currentMemberProfileID: UUID, now: Date) {
        authorName = result.entry.authorNameSnapshot
        authorAvatarEmoji = result.entry.authorAvatarSnapshot
        bodyText = result.entry.body.value
        createdAt = result.entry.createdAt
        isPermanent = result.entry.visibilityDuration == .permanent
        expirationLabel = DiaryExpirationFormatter.label(expiresAt: result.entry.expiresAt, now: now)
        isOwnEntry = result.entry.authorProfileID == currentMemberProfileID
        entryReactionSummary = Self.summarize(result.entryReactions.map(\.emoji))
        currentMemberEntryReactionEmoji = result.entryReactions
            .first { $0.memberProfileID == currentMemberProfileID }?.emoji.value

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
                currentMemberReactionEmoji: reactionsForComment
                    .first { $0.memberProfileID == currentMemberProfileID }?.emoji.value
            )
        }
    }

    private static func summarize(_ emojis: [DiaryReactionEmoji]) -> [ReactionSummaryItem] {
        var counts: [String: Int] = [:]
        for emoji in emojis { counts[emoji.value, default: 0] += 1 }
        return counts
            .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
            .map { ReactionSummaryItem(emoji: $0.key, count: $0.value) }
    }
}
