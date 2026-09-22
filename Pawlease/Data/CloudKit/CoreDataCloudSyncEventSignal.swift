import CoreData

/// Implements `CloudSyncEventSignaling` over `NSPersistentCloudKitContainer.eventChangedNotification`,
/// the only platform API that gives genuine evidence of import/export
/// progress. Never invents a "synced" status without an event to back it.
final class CoreDataCloudSyncEventSignal: CloudSyncEventSignaling, @unchecked Sendable {
    private let container: NSPersistentCloudKitContainer

    init(container: NSPersistentCloudKitContainer) {
        self.container = container
    }

    func syncEvents() -> AsyncStream<CircleSyncStatus> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification,
                object: container,
                queue: .main
            ) { notification in
                guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }
                guard event.type == .import || event.type == .export else { return }

                if event.endDate == nil {
                    continuation.yield(.syncing)
                } else if let error = event.error {
                    continuation.yield(.syncFailed(message: error.localizedDescription))
                } else {
                    continuation.yield(.synced)
                }
            }
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
