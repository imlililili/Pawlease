import SwiftUI

/// The small per-life-stage pet emoji — shown only beside the pet's name
/// (e.g. "🐣 Mochi"), never as standalone hero content. The hero square
/// itself shows Today's Moment's photo (see `PetArtworkStatusView`); this
/// view is deliberately just the emoji glyph so the caller controls size,
/// placement, and accessibility treatment.
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
        Text(emoji)
    }
}
