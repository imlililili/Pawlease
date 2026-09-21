import SwiftUI

/// Phase 1 is fully local-first, so sync status is always "saved on this
/// device." Per-moment CloudKit sync status arrives in a later phase.
struct SyncStatusBadge: View {
    var body: some View {
        Label("Saved on this device", systemImage: "checkmark.icloud")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Your moments are saved on this device")
    }
}
