import SwiftUI

/// Reflects `CircleSyncStatus` — only ever states the platform actually
/// gave evidence for (see `CircleSyncStatus` and `CoreDataCloudSyncEventSignal`).
struct SyncStatusBadge: View {
    let status: CircleSyncStatus

    var body: some View {
        Label(status.displayName, systemImage: status.systemImageName)
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityLabel(status.displayName)
    }
}
