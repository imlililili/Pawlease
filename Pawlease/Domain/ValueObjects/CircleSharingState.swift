/// Where a Circle stands in the CloudKit sharing lifecycle, from this
/// device's point of view.
enum CircleSharingState: Sendable, Equatable {
    /// No `CKShare` exists yet — the Circle only lives on this device (and,
    /// privately, this user's other devices via CloudKit private sync).
    case localOnly
    /// A share is actively being created or fetched.
    case preparing
    /// This device owns the Circle and has an active `CKShare` for it.
    case shared
    /// This device joined the Circle via an accepted invitation.
    case joined
    /// Sharing can't be determined right now (no iCloud account, offline).
    case unavailable
    case failed(message: String)

    var displayName: String {
        switch self {
        case .localOnly: "Not shared yet"
        case .preparing: "Preparing invitation…"
        case .shared: "Shared with your Circle"
        case .joined: "Joined via invitation"
        case .unavailable: "Sharing unavailable"
        case .failed(let message): message
        }
    }
}
