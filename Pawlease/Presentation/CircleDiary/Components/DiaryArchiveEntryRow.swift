import SwiftUI

/// One row in My Archive: author, original date, body, an "Expired ·
/// archived for you" badge, and the entry's reaction/comment counts —
/// archived content is read-only here (delete still lives on the Detail
/// screen this row pushes to).
struct DiaryArchiveEntryRow: View {
    let item: DiaryArchiveViewModel.ArchivedEntryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                AvatarView(name: item.entry.authorNameSnapshot, identitySeed: item.entry.authorProfileID.uuidString, diameter: 36)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(item.entry.authorNameSnapshot)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PawleaseTheme.textPrimary)
                        Text("·")
                            .foregroundStyle(PawleaseTheme.textSecondary)
                        Text(item.entry.createdAt, format: .dateTime.month(.abbreviated).day())
                            .font(.subheadline)
                            .foregroundStyle(PawleaseTheme.textSecondary)
                    }
                }
                Spacer()
            }

            Text(item.entry.body.value)
                .font(.body)
                .foregroundStyle(PawleaseTheme.textPrimary)
                .lineLimit(4)

            Text("Expired · archived for you")
                .font(.caption.weight(.medium))
                .foregroundStyle(PawleaseTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(PawleaseTheme.divider.opacity(0.5), in: Capsule())

            HStack(spacing: 16) {
                if !item.reactions.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "heart")
                        if let summary = DiaryReactionFormatter.summaryLabel(for: item.reactions.map(\.emoji)) {
                            Text(summary)
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
        .accessibilityLabel("\(item.entry.authorNameSnapshot): \(item.entry.body.value). Expired, archived for you.")
    }
}
