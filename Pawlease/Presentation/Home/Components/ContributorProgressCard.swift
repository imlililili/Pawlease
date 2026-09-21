import SwiftUI

struct ContributorProgressCard: View {
    let state: PetHomeViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Contributors")
                .font(.headline)

            Text(state.progressLabel)
                .font(.largeTitle.bold())
                .accessibilityLabel(state.contributorAccessibilityLabel)

            Text(state.hasPosted ? "You've shared today." : "You haven't shared today yet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}
