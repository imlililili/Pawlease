/// A framework-free stream of sync status pulses, derived from real
/// platform evidence (`NSPersistentCloudKitContainer` import/export
/// events) rather than guessed or assumed. Implemented in the Data layer.
protocol CloudSyncEventSignaling: Sendable {
    func syncEvents() -> AsyncStream<CircleSyncStatus>
}
