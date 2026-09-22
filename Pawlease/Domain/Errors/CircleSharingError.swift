/// Semantic CloudKit-sharing failures. The Data layer maps `CKError` (and
/// other CloudKit-adjacent failures) into these before they ever reach
/// Application or Presentation — nothing above Data ever sees a `CKError`.
enum CircleSharingError: Error, Equatable, Sendable {
    case iCloudAccountUnavailable(CloudAccountAvailability)
    case networkUnavailable
    case rateLimited
    case serviceUnavailable
    case shareAlreadyExists
    case circleNotFound
    case invitationAcceptanceFailed(message: String)
    case zoneUnavailable
    case cancelled
    case unknown(message: String)

    var displayMessage: String {
        switch self {
        case .iCloudAccountUnavailable(let availability): availability.displayName
        case .networkUnavailable: "You're offline. Try again once you have a connection."
        case .rateLimited: "Too many requests right now. Please try again in a moment."
        case .serviceUnavailable: "iCloud is temporarily unavailable. Please try again shortly."
        case .shareAlreadyExists: "This Circle is already shared."
        case .circleNotFound: "We couldn't find your Circle."
        case .invitationAcceptanceFailed(let message): message
        case .zoneUnavailable: "iCloud couldn't prepare this Circle for sharing. Please try again."
        case .cancelled: "Sharing was cancelled."
        case .unknown(let message): message
        }
    }
}
