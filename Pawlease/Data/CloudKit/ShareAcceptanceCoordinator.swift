import CloudKit

/// Holds `CKShare.Metadata` handed to the app by
/// `application(_:userDidAcceptCloudKitShareWith:)` until
/// `CircleSharingRepository.acceptPendingInvitation()` is ready to process
/// it. This is the "dedicated coordinator" the AppDelegate adaptor forwards
/// to instead of implementing acceptance logic itself.
final class ShareAcceptanceCoordinator: @unchecked Sendable {
    static let shared = ShareAcceptanceCoordinator()

    private let lock = NSLock()
    private var pendingMetadata: CKShare.Metadata?

    func stage(_ metadata: CKShare.Metadata) {
        lock.lock()
        pendingMetadata = metadata
        lock.unlock()
    }

    func takePending() -> CKShare.Metadata? {
        lock.lock()
        defer { lock.unlock() }
        let metadata = pendingMetadata
        pendingMetadata = nil
        return metadata
    }

    var hasPendingInvitation: Bool {
        lock.lock()
        defer { lock.unlock() }
        return pendingMetadata != nil
    }
}
