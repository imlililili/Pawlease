import SwiftUI

/// A small "last updated" caption using `Text(_:style:)` — WidgetKit's
/// live-updating date text, not a timer we manage ourselves. Renders
/// nothing for the placeholder/no-data state (`lastUpdated == .distantPast`)
/// so it never shows a nonsensical "58 years ago."
struct LastUpdatedCaption: View {
    let lastUpdated: Date
    let now: Date

    private static let staleThreshold: TimeInterval = 6 * 60 * 60

    private var isStale: Bool {
        now.timeIntervalSince(lastUpdated) > Self.staleThreshold
    }

    var body: some View {
        if lastUpdated > .distantPast {
            Text(lastUpdated, style: .relative)
                .font(.caption2)
                .foregroundStyle(isStale ? Color.orange : Color.secondary)
        }
    }
}
