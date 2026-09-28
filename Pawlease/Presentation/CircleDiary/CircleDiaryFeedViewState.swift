import Foundation

/// Presentation-ready, pre-formatted state for the Circle Diary feed,
/// derived once from `LoadActiveDiaryFeedUseCase.FeedItem`s so the View
/// stays free of formatting logic.
struct CircleDiaryFeedViewState: Equatable {
    struct EntryItem: Equatable, Identifiable {
        let id: UUID
        let authorAvatarEmoji: String
        let authorName: String
        let createdAt: Date
        let bodyText: String
        let isPermanent: Bool
        /// e.g. "Expires in 18h" — `nil` for a permanent entry.
        let expirationLabel: String?
        let commentCount: Int
        /// e.g. "❤️ 2  🌼 1" — `nil` when there are no reactions yet.
        let reactionSummaryLabel: String?
    }

    let entries: [EntryItem]

    init(items: [LoadActiveDiaryFeedUseCase.FeedItem], now: Date) {
        entries = items.map { item in
            EntryItem(
                id: item.entry.id,
                authorAvatarEmoji: item.entry.authorAvatarSnapshot,
                authorName: item.entry.authorNameSnapshot,
                createdAt: item.entry.createdAt,
                bodyText: item.entry.body.value,
                isPermanent: item.entry.visibilityDuration == .permanent,
                expirationLabel: DiaryExpirationFormatter.label(expiresAt: item.entry.expiresAt, now: now),
                commentCount: item.commentCount,
                reactionSummaryLabel: DiaryReactionFormatter.summaryLabel(for: item.reactions.map(\.emoji))
            )
        }
    }
}

/// Shared "Expires in …" formatting so the Feed and Detail screens agree on
/// wording. Pure function of `expiresAt`/`now` — never reads the system
/// clock itself.
enum DiaryExpirationFormatter {
    static func label(expiresAt: Date?, now: Date) -> String? {
        guard let expiresAt else { return nil }
        let remaining = expiresAt.timeIntervalSince(now)
        guard remaining > 0 else { return "Expired" }

        let totalMinutes = Int(remaining / 60)
        if totalMinutes < 60 {
            return "Expires in \(max(1, totalMinutes))m"
        }
        let totalHours = totalMinutes / 60
        if totalHours < 24 {
            return "Expires in \(totalHours)h"
        }
        let totalDays = totalHours / 24
        return "Expires in \(totalDays)d"
    }
}

/// Shared reaction-summary formatting for any free-keyboard-emoji reaction
/// list (Diary entries and Diary comments both use this).
enum DiaryReactionFormatter {
    static func summaryLabel(for emojis: [DiaryReactionEmoji]) -> String? {
        guard !emojis.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for emoji in emojis { counts[emoji.value, default: 0] += 1 }
        let ordered = counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }
        return ordered.map { "\($0.key) \($0.value)" }.joined(separator: "  ")
    }
}
