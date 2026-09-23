import Foundation

/// A focused abstraction over the App Group "share inbox" filesystem —
/// deliberately not raw `FileManager`/`UserDefaults` calls scattered across
/// the Share Extension and the main app. Image bytes are always files, never
/// `UserDefaults`. Implemented by `AppGroupShareInboxStore`.
///
/// The Share Extension only ever calls `saveShare`. The main app only ever
/// calls the read/list/remove side. Both go through the same type so the
/// wire format (manifest JSON + sibling image file) can never drift.
protocol ShareInboxStoring: Sendable {
    /// Writes the image file and its manifest atomically (the image is
    /// written first; if the manifest write fails, the orphaned image is
    /// rolled back). Throws `ShareInboxError.appGroupUnavailable` if the App
    /// Group container can't be resolved — callers must not crash on this.
    @discardableResult
    func saveShare(
        id: UUID,
        imageData: Data,
        caption: String?,
        createdAt: Date,
        source: String
    ) throws -> PendingShareManifest

    /// All pending manifests, in deterministic order (oldest first, ties
    /// broken by id). Never throws: an unreadable inbox directory or a
    /// corrupt individual manifest both simply yield fewer results — a
    /// corrupt manifest file is removed as part of listing, since it
    /// carries no recoverable data on its own.
    func loadPendingManifests() -> [PendingShareManifest]

    /// Reads the image bytes for a relative filename, rejecting anything
    /// that isn't a bare filename (no path separators, no `.`/`..`) so a
    /// malformed or tampered manifest can never resolve outside the inbox's
    /// images directory. Returns `nil` on any failure — never throws.
    func loadImageData(filename: String) -> Data?

    /// Removes only the manifest for `id`. Used right after a successful
    /// import: the bookkeeping is no longer needed, but the image file the
    /// newly-saved `PendingPostDraft` still references is deliberately left
    /// alone.
    func removeManifest(id: UUID)

    /// Removes only the image file for `filename`. Used once a draft's
    /// image has been fully consumed (published) and is no longer needed
    /// anywhere.
    func removeImage(filename: String)
}

enum ShareInboxError: Error, Sendable, Equatable {
    /// `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`
    /// returned nil — the App Group entitlement is missing or misconfigured
    /// for this build.
    case appGroupUnavailable
}
