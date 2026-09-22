import SwiftUI

/// A compact read-out of reaction counts, e.g. "❤️ 3  🔥 1". Renders nothing
/// when there are no reactions yet.
struct ReactionSummary: View {
    let items: [PostDetailViewState.ReactionSummaryItem]

    var body: some View {
        if !items.isEmpty {
            HStack(spacing: 10) {
                ForEach(items) { item in
                    HStack(spacing: 2) {
                        Text(item.emoji.rawValue)
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.count) \(item.emoji.accessibilityName) reaction\(item.count == 1 ? "" : "s")")
                }
            }
        }
    }
}
