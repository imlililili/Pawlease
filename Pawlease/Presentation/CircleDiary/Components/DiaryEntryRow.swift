import SwiftUI

/// One row in the Circle Diary feed — a clean vertical Threads/X-style row,
/// not an oversized card: avatar emoji, name, relative timestamp, body,
/// expiration label, comment count, and reaction summary.
struct DiaryEntryRow: View {
    let item: CircleDiaryFeedViewState.EntryItem
    let isShielded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(item.authorAvatarEmoji)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.authorName)
                        .font(.subheadline.bold())
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let expirationLabel = item.expirationLabel {
                    Text(expirationLabel)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            if isShielded && !item.isPermanent {
                PrivacyShieldView()
            } else {
                Text(item.bodyText)
                    .font(.body)
                    .lineLimit(6)
            }

            HStack(spacing: 14) {
                Label("\(item.commentCount)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(item.commentCount) comment\(item.commentCount == 1 ? "" : "s")")
                if let reactionSummaryLabel = item.reactionSummaryLabel {
                    Text(reactionSummaryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.authorName), \(isShielded && !item.isPermanent ? "content hidden for privacy" : item.bodyText)"
        )
    }
}
