import SwiftUI

/// Placeholder pet artwork keyed to life stage. Final animated artwork is
/// deferred to a later phase.
struct PetArtworkView: View {
    let stage: PetLifeStage

    private var emoji: String {
        switch stage {
        case .egg: "🥚"
        case .hatchling: "🐣"
        case .juvenile: "🦊"
        case .adult: "🦊"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.petArtworkBackground)
            Text(emoji)
                .font(.system(size: 64))
        }
        .accessibilityHidden(true)
    }
}
