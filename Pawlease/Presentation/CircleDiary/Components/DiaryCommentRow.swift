import SwiftUI

/// One Diary comment row. A removed comment shows "Comment removed" in
/// place of its original text and loses its reaction control, but keeps
/// its author and timestamp — the underlying record is never erased.
struct DiaryCommentRow: View {
    let comment: DiaryEntryDetailViewState.CommentItem
    let onReact: (String) -> Void
    let onRemoveReaction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(comment.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(comment.displayBody)
                    .font(.body)
                    .foregroundStyle(comment.isRemoved ? Color.secondary : Color.primary)
                    .italic(comment.isRemoved)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(comment.authorName): \(comment.displayBody)")

            if comment.isRemoved {
                DiaryReactionSummaryView(items: comment.reactionSummary)
            } else {
                HStack {
                    DiaryReactionEntryField(
                        currentReactionEmoji: comment.currentMemberReactionEmoji,
                        onSubmit: onReact,
                        onRemove: onRemoveReaction
                    )
                    DiaryReactionSummaryView(items: comment.reactionSummary)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 6)
    }
}
