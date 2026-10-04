import SwiftUI

/// Pet Home's Circle Diary preview: a section header with a "See all" link
/// to the full feed, and the single newest active entry as a preview row.
struct CircleDiaryPreviewSection: View {
    let circleName: String
    let latestEntry: LoadActiveDiaryFeedUseCase.FeedItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Circle Diary")
                        .font(.title3.bold())
                        .foregroundStyle(PawleaseTheme.textPrimary)
                    Text("Just for \(circleName)")
                        .font(.footnote)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                }
                Spacer()
                NavigationLink(value: CircleDiaryRoute()) {
                    Label("See all", systemImage: "chevron.right")
                        .labelStyle(.trailingIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PawleaseTheme.accentPrimary)
                }
                .accessibilityHint("Opens the full Circle Diary feed")
            }

            Rectangle()
                .fill(PawleaseTheme.divider)
                .frame(height: 1)

            if let latestEntry {
                previewRow(for: latestEntry)
            } else {
                Text("No Diary entries yet. Be the first to share a thought.")
                    .font(.subheadline)
                    .foregroundStyle(PawleaseTheme.textSecondary)
            }
        }
    }

    private func previewRow(for item: LoadActiveDiaryFeedUseCase.FeedItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(name: item.entry.authorNameSnapshot, identitySeed: item.entry.authorProfileID.uuidString, diameter: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.entry.authorNameSnapshot)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PawleaseTheme.textPrimary)
                    Text("·")
                        .foregroundStyle(PawleaseTheme.textSecondary)
                    Text(item.entry.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                }
                Text(item.entry.body.value)
                    .font(.subheadline)
                    .foregroundStyle(PawleaseTheme.textPrimary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
                .font(.caption.weight(.semibold))
        }
    }
}

private extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}
