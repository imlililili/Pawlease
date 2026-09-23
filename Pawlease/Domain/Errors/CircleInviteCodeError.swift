/// Semantic failures for the invite-code workflow. The Data layer maps
/// `CKError` (and its own defensive-parsing failures) into these before
/// they ever reach Application or Presentation.
enum CircleInviteCodeError: Error, Equatable, Sendable {
    /// Rejected by domain validation before any CloudKit request was made.
    case malformed
    case notFound
    case expired
    case revoked
    case offline
    case accountUnavailable
    /// A freshly generated code collided with an existing record ID.
    case collision
    /// Every collision retry was exhausted.
    case retryLimitExceeded
    /// The fetched record failed defensive validation (wrong record type,
    /// bad URL, bad UUID, unsupported schema version, etc.).
    case invalidRecord
    case permissionFailure
    /// Publishing was attempted without a saved CKShare URL to publish.
    case shareURLUnavailable
    case unknown(message: String)

    var displayMessage: String {
        switch self {
        case .malformed: "That invite code doesn't look right. Please check it and try again."
        case .notFound: "We couldn't find a Circle for that invite code."
        case .expired: "This invite code has expired. Ask your friend for a new one."
        case .revoked: "This invite code is no longer active."
        case .offline: "You're offline. Try again once you have a connection."
        case .accountUnavailable: "Sign in to iCloud to join a Circle."
        case .collision: "We hit a temporary issue generating your code. Please try again."
        case .retryLimitExceeded: "We couldn't generate a unique invite code right now. Please try again shortly."
        case .invalidRecord: "That invite code isn't valid."
        case .permissionFailure: "iCloud didn't allow that action. Please try again."
        case .shareURLUnavailable: "We couldn't prepare a sharing link for this Circle yet. Please try again."
        case .unknown(let message): message
        }
    }
}
