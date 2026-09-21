import SwiftUI

struct PetStateCard: View {
    let state: PetHomeViewState

    var body: some View {
        VStack(spacing: 12) {
            PetArtworkView(stage: state.petStage)
                .frame(width: 140, height: 140)

            Text(state.petName)
                .font(.title2.bold())

            Text(state.activityStateLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(state.streakLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.petName), \(state.activityStateLabel), \(state.streakLabel)")
    }
}
