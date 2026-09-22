import CoreData

/// Implements `RemoteChangeSignaling` over Core Data's own remote-change
/// notification. One pulse per store change CloudKit mirrors in — never a
/// timer.
final class CoreDataRemoteChangeSignal: RemoteChangeSignaling, @unchecked Sendable {
    private let container: NSPersistentCloudKitContainer

    init(container: NSPersistentCloudKitContainer) {
        self.container = container
    }

    func remoteChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator,
                queue: .main
            ) { _ in
                continuation.yield(())
            }
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
