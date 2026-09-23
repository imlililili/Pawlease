import Foundation

/// Reads and writes `WidgetSnapshot` through `UserDefaults(suiteName:)` in
/// the shared App Group container. The only place either the main app or
/// the Widget extension touches `UserDefaults` for this data — everything
/// else goes through `WidgetSnapshotStoring`.
final class AppGroupWidgetSnapshotStore: WidgetSnapshotStoring, @unchecked Sendable {
    static let appGroupIdentifier = "group.com.lili.Pawlease"
    private static let storageKey = "widgetSnapshot.v1"

    private let userDefaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// `appGroupIdentifier` is overridable so tests can point this at a
    /// throwaway suite name — no App Group entitlement, Core Data, or
    /// CloudKit involved either way.
    init(appGroupIdentifier: String = AppGroupWidgetSnapshotStore.appGroupIdentifier) {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }

    func save(_ snapshot: WidgetSnapshot) throws {
        guard let userDefaults else {
            throw WidgetSnapshotStoreError.appGroupUnavailable
        }
        let data = try encoder.encode(snapshot)
        userDefaults.set(data, forKey: Self.storageKey)
    }

    func loadSnapshot() -> WidgetSnapshot {
        guard let userDefaults, let data = userDefaults.data(forKey: Self.storageKey) else {
            return .placeholder
        }
        guard let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }
}
