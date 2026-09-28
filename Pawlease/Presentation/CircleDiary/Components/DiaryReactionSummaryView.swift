import SwiftUI

/// A compact read-out of free-keyboard-emoji reaction counts, e.g.
/// "❤️ 3  🌼 1". Renders nothing when there are no reactions yet.
struct DiaryReactionSummaryView: View {
    let items: [DiaryEntryDetailViewState.ReactionSummaryItem]

    var body: some View {
        if !items.isEmpty {
            HStack(spacing: 10) {
                ForEach(items) { item in
                    HStack(spacing: 2) {
                        Text(item.emoji)
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.count) reaction\(item.count == 1 ? "" : "s") of \(item.emoji)")
                }
            }
        }
    }
}
