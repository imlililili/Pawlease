import SwiftUI

/// One row in the Circle Diary feed — a clean vertical Threads/X-style row,
/// not an oversized card: avatar emoji, name, relative timestamp, body,
/// expiration label, comment count, and reaction summary.
struct DiaryEntryRow: View {
    let item: CircleDiaryFeedViewState.EntryItem
    /// Read directly here, in this row's own body — not precomputed by an
    /// ancestor and passed down as a `Bool`. `DiaryPrivacyMonitor` updates
    /// live as capture/foreground state changes; if an ancestor like
    /// `CircleDiaryFeedView` read `shouldShieldTimedContent` itself, every
    /// such tick would re-evaluate that ancestor's entire body — including
    /// the `.navigationDestination(for: DiaryEntryRoute.self)` it owns,
    /// causing SwiftUI to re-invoke that destination closure while a push
    /// was still settling. Confirmed via direct instrumentation: this
    /// produced two separate destination view constructions for one push
    /// and made the navigation stack unable to stay pushed. Scoping the
    /// read to this leaf view keeps `@Observable`'s dependency tracking
    /// local to the row, so only the row re-renders on a shield tick.
    let privacyMonitor: DiaryPrivacyMonitor

    private var isShielded: Bool { privacyMonitor.shouldShieldTimedContent }

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
