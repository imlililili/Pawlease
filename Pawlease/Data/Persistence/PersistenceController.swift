import CloudKit
import CoreData

/// Owns the `NSPersistentCloudKitContainer`. This is the only place business
/// logic may treat Core Data as a singleton — repositories receive the
/// container through initializers rather than reaching for `.shared`
/// themselves.
///
/// Two persistent stores are configured, matching the Core Data model's two
/// configurations:
///  - **Private** (`UserProfileEntity`, `PendingPostDraftEntity`) — scope
///    `.private`. Never shared with anyone; syncs privately across the
///    signed-in user's own devices.
///  - **Shared** (`CircleEntity` and everything under it) — scope `.shared`.
///    Holds the Circle graph.
///
/// KNOWN LIMITATION (documented, not silently assumed correct): per Apple's
/// `NSPersistentCloudKitContainer` sharing model, a `.shared`-scope store is
/// populated by *accepted invitations* — it has no CloudKit zone of its own
/// to originate brand-new records into. This app's `Shared` configuration is
/// used for both "a Circle I own" and "a Circle I joined," following this
/// feature's literal design brief, but that has not been verified against
/// real CloudKit (see the README's CloudKit section and manual two-device
/// procedure). A production hardening pass would likely adopt Apple's
/// dual-scope-same-configuration pattern instead (one configuration loaded
/// by both a `.private`-scope store, for owned/not-yet-shared objects, and
/// a `.shared`-scope store, for joined ones). See also
/// `CloudKitCircleSharingRepository.swift`.
///
/// The app must never crash because iCloud is unavailable, the user is
/// signed out, or CloudKit is temporarily unreachable — `loadPersistentStores`
/// only logs failures here; Use Cases and ViewModels are responsible for
/// surfacing a "local only" / "unavailable" state instead of trusting that
/// sync succeeded.
final class PersistenceController: @unchecked Sendable {
    static let cloudKitContainerIdentifier = "iCloud.com.lili.Pawlease"
    static let privateConfigurationName = "Private"
    static let sharedConfigurationName = "Shared"

    static let shared = PersistenceController(mode: .live)

    static var preview: PersistenceController {
        PersistenceController(mode: .inMemory)
    }

    enum Mode {
        /// Real, on-disk stores. CloudKit-backed when entitlements and an
        /// iCloud account are available; degrades to local-only storage
        /// otherwise (see the doc comment above).
        case live
        /// Ephemeral, local-only stores with no CloudKit involvement at
        /// all — used by tests and SwiftUI previews so neither requires an
        /// iCloud account or network access.
        case inMemory
    }

    let container: NSPersistentCloudKitContainer

    /// `true` only for `.live` mode — i.e. whether this controller *attempted*
    /// to configure CloudKit-backed stores. This does not mean sync is
    /// actually working (see `CheckCloudAccountUseCase` for that signal).
    let isCloudKitConfigured: Bool

    init(mode: Mode = .live) {
        let container = NSPersistentCloudKitContainer(name: "Pawlease")

        switch mode {
        case .inMemory:
            // NSInMemoryStoreType does not reliably track per-configuration
            // version hashes when two in-memory stores are opened from one
            // model at once (observed as a spurious "model configuration...
            // incompatible with the store" error). Temporary on-disk SQLite
            // stores don't have that problem, still require no iCloud
            // account or network access, and are deleted with the OS's
            // normal temp-directory cleanup.
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("Pawlease-Preview-\(UUID().uuidString)", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let privateDescription = NSPersistentStoreDescription(
                url: directory.appendingPathComponent("Private.sqlite")
            )
            privateDescription.configuration = Self.privateConfigurationName

            let sharedDescription = NSPersistentStoreDescription(
                url: directory.appendingPathComponent("Shared.sqlite")
            )
            sharedDescription.configuration = Self.sharedConfigurationName

            container.persistentStoreDescriptions = [privateDescription, sharedDescription]
            isCloudKitConfigured = false

        case .live:
            let directory = Self.storeDirectory()
            let privateDescription = NSPersistentStoreDescription(
                url: directory.appendingPathComponent("Private.sqlite")
            )
            privateDescription.configuration = Self.privateConfigurationName
            Self.enableCloudKitSync(on: privateDescription, scope: .private)

            let sharedDescription = NSPersistentStoreDescription(
                url: directory.appendingPathComponent("Shared.sqlite")
            )
            sharedDescription.configuration = Self.sharedConfigurationName
            Self.enableCloudKitSync(on: sharedDescription, scope: .shared)

            container.persistentStoreDescriptions = [privateDescription, sharedDescription]
            isCloudKitConfigured = true
        }

        container.loadPersistentStores { description, error in
            if let error {
                // Deliberately non-fatal: iCloud may be signed out, the
                // network may be unavailable, or the CloudKit container may
                // not yet be provisioned in the Developer Portal. The app
                // must still launch and show a local/unavailable state
                // rather than crash.
                print("Pawlease: persistent store '\(description.configuration ?? "?")' failed to load: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        // Local edits win on conflicting properties: this keeps an
        // optimistically-saved local moment visible even if a stale
        // CloudKit import races it, while still merging in *new* remote
        // data for properties the local save didn't touch.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        self.container = container
    }

    /// Enables persistent history tracking, remote change notifications, and
    /// CloudKit mirroring for one store description. Lightweight migration
    /// is on by default for `NSPersistentStoreDescription`, which is what we
    /// want for local schema evolution.
    private static func enableCloudKitSync(on description: NSPersistentStoreDescription, scope: CKDatabase.Scope) {
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)
        options.databaseScope = scope
        description.cloudKitContainerOptions = options
    }

    /// The directory the two live stores live in. Deliberately **not** the
    /// legacy single-store location (`Application Support/Pawlease.sqlite`,
    /// used by `NSPersistentContainer(name: "Pawlease")` in earlier phases)
    /// — see the migration note in this file's header comment and the
    /// README's "Known limitations" section for why this phase creates new
    /// store files rather than migrating the old one in place.
    private static func storeDirectory() -> URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Pawlease", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
}
