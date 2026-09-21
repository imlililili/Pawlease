/// The pet's condition for the current Circle day, always derived from
/// today's `DailyCareStatus` rather than a stored, mutable flag — so it can
/// never be permanently "killed" and multiple devices never disagree.
enum PetActivityState: Sendable, Equatable {
    case thriving
    case resting

    var displayName: String {
        switch self {
        case .thriving: "Thriving"
        case .resting: "Resting"
        }
    }
}
