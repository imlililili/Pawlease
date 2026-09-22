import SwiftUI

/// A compact visual progress treatment for today's distinct-contributor
/// count (e.g. `1/2`). Uses semantic colors so it holds contrast in both
/// light and dark mode.
struct ContributorProgressBar: View {
    let current: Int
    let required: Int

    private var fraction: Double {
        guard required > 0 else { return 0 }
        return min(Double(current) / Double(required), 1.0)
    }

    private var isComplete: Bool {
        fraction >= 1.0
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                Capsule()
                    .fill(isComplete ? Color.green : Color.accentColor)
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
