/// The current device's iCloud account state, expressed in product terms
/// rather than `CKAccountStatus`. Only `.available` allows preparing or
/// accepting a Circle invitation.
enum CloudAccountAvailability: Sendable, Equatable {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case unknown

    var allowsSharing: Bool {
        self == .available
    }

    var displayName: String {
        switch self {
        case .available: "Connected"
        case .noAccount: "Not signed in to iCloud"
        case .restricted: "iCloud restricted"
        case .temporarilyUnavailable: "iCloud temporarily unavailable"
        case .unknown: "iCloud status unknown"
        }
    }
}
