import SwiftUI

/// One row in the Circle Diary feed — a clean vertical Threads/X-style row,
/// not an oversized card: avatar initials, name, relative timestamp, body,
/// visibility badge, reaction summary, and comment count.
struct DiaryEntryRow: View {
    let item: CircleDiaryFeedViewState.EntryItem
    let isOwnEntry: Bool
    let onDelete: () -> Void
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                AvatarView(name: item.authorName, identitySeed: item.authorProfileID.uuidString, diameter: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PawleaseTheme.textPrimary)
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                }
                Spacer()

                if isOwnEntry {
                    Menu {
                        Button("Delete Entry", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(PawleaseTheme.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("More options for your entry")
                }
            }

            if isShielded && !item.isPermanent {
                PrivacyShieldView()
            } else {
                Text(item.bodyText)
                    .font(.body)
                    .foregroundStyle(PawleaseTheme.textPrimary)
                    .lineLimit(6)
            }

            visibilityBadge

            HStack(spacing: 16) {
                if item.reactionCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "heart")
                            .foregroundStyle(PawleaseTheme.textSecondary)
                        if let reactionSummaryLabel = item.reactionSummaryLabel {
                            Text(reactionSummaryLabel)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(PawleaseTheme.textSecondary)
                }

                Label("\(item.commentCount)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundStyle(PawleaseTheme.textSecondary)
                    .accessibilityLabel("\(item.commentCount) comment\(item.commentCount == 1 ? "" : "s")")
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.authorName), \(isShielded && !item.isPermanent ? "content hidden for privacy" : item.bodyText)"
        )
    }

    private var visibilityBadge: some View {
        Text(item.expirationLabel ?? "Permanent")
            .font(.caption.weight(.medium))
            .foregroundStyle(PawleaseTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(PawleaseTheme.divider.opacity(0.5), in: Capsule())
    }
}
