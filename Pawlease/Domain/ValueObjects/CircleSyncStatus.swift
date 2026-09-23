/// A small, honest synchronization status for display. Only reflects states
/// the platform actually gives us evidence for — `NSPersistentCloudKitContainer`
/// event notifications for `.syncing`/`.synced`/`.syncFailed`, and
/// `CloudAccountStatusProviding` for the account-level states. Never claims
/// precise per-record CloudKit completion.
enum CircleSyncStatus: Sendable, Equatable {
    case localChangesSaved
    case syncing
    case synced
    case offline
    case iCloudUnavailable
    case syncFailed(message: String)

    var displayName: String {
        switch self {
        case .localChangesSaved: "Saved on this device"
        case .syncing: "Syncing…"
        case .synced: "Synced with iCloud"
        case .offline: "Offline — saved on this device"
        case .iCloudUnavailable: "iCloud unavailable — saved on this device"
        case .syncFailed: "Sync couldn't finish — saved on this device"
        }
    }

    var systemImageName: String {
        switch self {
        case .localChangesSaved: "checkmark.icloud"
        case .syncing: "arrow.triangle.2.circlepath.icloud"
        case .synced: "checkmark.icloud.fill"
        case .offline: "icloud.slash"
        case .iCloudUnavailable: "icloud.slash"
        case .syncFailed: "exclamationmark.icloud"
        }
    }
}
