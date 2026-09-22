import SwiftUI

/// One comment row. A removed comment shows "Comment removed" in place of
/// its original text and loses its reaction/delete controls, but keeps its
/// author and timestamp — the underlying record is never erased.
struct CommentRow: View {
    let comment: PostDetailViewState.CommentItem
    let onReact: (ReactionEmoji) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(comment.createdAt, style: .time)
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
                ReactionSummary(items: comment.reactionSummary)
            } else {
                HStack {
                    ReactionPicker(selectedEmoji: comment.currentMemberReaction, onSelect: onReact)
                    ReactionSummary(items: comment.reactionSummary)
                    Spacer()
                    if comment.isOwnComment {
                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Delete your comment")
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
