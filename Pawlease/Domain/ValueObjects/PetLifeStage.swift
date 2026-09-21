/// The pet's cumulative growth stage. Never regresses due to a missed day —
/// only forward progress through care over time.
enum PetLifeStage: Int16, Sendable, CaseIterable {
    case egg = 0
    case hatchling = 1
    case juvenile = 2
    case adult = 3

    var displayName: String {
        switch self {
        case .egg: "Egg"
        case .hatchling: "Hatchling"
        case .juvenile: "Juvenile"
        case .adult: "Adult"
        }
    }
}
