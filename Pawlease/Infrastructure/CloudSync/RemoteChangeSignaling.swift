/// A framework-free stream of "something changed remotely" pulses. The Data
/// layer implements this on top of Core Data's remote-change notification
/// (`NSPersistentStoreRemoteChangeNotification`) so Presentation can react
/// to CloudKit-driven updates without importing CoreData or CloudKit
/// itself. Never a repeating timer — one pulse per actual store change.
protocol RemoteChangeSignaling: Sendable {
    func remoteChanges() -> AsyncStream<Void>
}
