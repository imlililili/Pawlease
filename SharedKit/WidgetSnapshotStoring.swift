import Foundation

/// A focused abstraction over where the widget snapshot lives — deliberately
/// not `UserDefaults` itself, so nothing outside this one small surface
/// (Views, ViewModels, the Widget's own code) ever touches `UserDefaults`
/// directly. Implemented by `AppGroupWidgetSnapshotStore`.
protocol WidgetSnapshotStoring: Sendable {
    /// Persists `snapshot`. Throws on genuine failure (App Group
    /// unavailable, encode failure) — callers must not crash on this, only
    /// skip whatever depended on a successful write (e.g. a timeline
    /// reload).
    func save(_ snapshot: WidgetSnapshot) throws

    /// Never throws and never returns nil: falls back to
    /// `WidgetSnapshot.placeholder` if the App Group is unavailable, no
    /// snapshot has been written yet, or the stored data fails to decode.
    func loadSnapshot() -> WidgetSnapshot
}

enum WidgetSnapshotStoreError: Error, Sendable, Equatable {
    /// `UserDefaults(suiteName:)` returned nil — the App Group entitlement
    /// is missing or misconfigured for this build.
    case appGroupUnavailable
}
