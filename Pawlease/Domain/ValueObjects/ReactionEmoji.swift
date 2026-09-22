/// The fixed set of emoji reactions Pawlease supports on moments and
/// comments. A closed set — rather than an arbitrary `String` — makes an
/// unsupported reaction unrepresentable.
enum ReactionEmoji: String, CaseIterable, Sendable, Equatable {
    case heart = "❤️"
    case laugh = "😂"
    case comfort = "🥺"
    case fire = "🔥"
    case paw = "🐾"

    var accessibilityName: String {
        switch self {
        case .heart: "heart"
        case .laugh: "laugh"
        case .comfort: "comfort"
        case .fire: "fire"
        case .paw: "paw"
        }
    }
}
