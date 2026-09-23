/// Maps a `SharedPet.speciesKey` (Domain layer, main app only) to a
/// placeholder emoji. Kept in `SharedKit` — not the Domain layer itself —
/// because the Widget extension needs it too and cannot import the main
/// app's Domain module. Final animated artwork is deferred to a later
/// phase, matching `PetArtworkView` in the main app.
enum PetSpeciesArtwork {
    static func emoji(forSpeciesKey speciesKey: String) -> String {
        switch speciesKey {
        case "fox": "🦊"
        case "dog": "🐶"
        case "cat": "🐱"
        case "rabbit": "🐰"
        case "bird": "🐦"
        default: "🐾"
        }
    }
}
