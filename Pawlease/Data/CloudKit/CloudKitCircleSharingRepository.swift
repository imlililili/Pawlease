import CloudKit
import CoreData

/// Implements `CircleSharingRepository` using `NSPersistentCloudKitContainer`'s
/// sharing APIs. This is the only place in the app that touches `CKShare`
/// for Circle sharing.
///
/// See `PersistenceController`'s header comment for a documented, known
/// limitation: this app creates a Circle directly against the `Shared`
/// configuration's store rather than the more general Apple sample pattern
/// (owned objects in a `.private`-scope store, migrated to `.shared` on
/// first share). That has not been verified against real CloudKit.
final class CloudKitCircleSharingRepository: CircleSharingRepository, @unchecked Sendable {
    private let container: NSPersistentCloudKitContainer
    private let shareAcceptanceCoordinator: ShareAcceptanceCoordinator

    init(container: NSPersistentCloudKitContainer, shareAcceptanceCoordinator: ShareAcceptanceCoordinator) {
        self.container = container
        self.shareAcceptanceCoordinator = shareAcceptanceCoordinator
    }

    func sharingState(circleID: UUID) async throws -> CircleSharingState {
        let context = container.newBackgroundContext()
        do {
            return try await context.perform { [container] in
                guard let entity = try Self.fetchCircleEntity(circleID: circleID, context: context) else {
                    throw CircleSharingError.circleNotFound
                }
                let shares = try container.fetchShares(matching: [entity.objectID])
                guard let share = shares[entity.objectID] else {
                    return .localOnly
                }
                if share.currentUserParticipant?.role == .owner {
                    return .shared
                }
                return .joined
            }
        } catch let error as CircleSharingError {
            throw error
        } catch {
            throw CircleSharingErrorMapping.map(error)
        }
    }

    /// Creating a `CKShare` requires a live `NSManagedObject` on the main
    /// thread — `NSPersistentCloudKitContainer.share(_:to:)` takes managed
    /// objects, not object IDs, and Apple's own sample code invokes it from
    /// `viewContext`. This method therefore runs on the main actor rather
    /// than a background context, unlike the rest of this file.
    @MainActor
    @discardableResult
    func prepareShare(circleID: UUID) async throws -> PreparedCircleShare {
        let context = container.viewContext

        do {
            let entity = try context.performAndWait { () -> CircleEntity in
                guard let entity = try Self.fetchCircleEntity(circleID: circleID, context: context) else {
                    throw CircleSharingError.circleNotFound
                }
                return entity
            }

            let existingShares = try context.performAndWait {
                try container.fetchShares(matching: [entity.objectID])
            }
            if existingShares[entity.objectID] != nil {
                // Reuse rather than duplicate.
                return PreparedCircleShare(circleID: circleID, isNewShare: false)
            }

            let (_, share, _) = try await container.share([entity], to: nil)
            share[CKShare.SystemFieldKey.title] = "Pawlease Circle" as CKRecordValue
            let ckContainer = CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier)
            _ = try await ckContainer.privateCloudDatabase.save(share)

            return PreparedCircleShare(circleID: circleID, isNewShare: true)
        } catch let error as CircleSharingError {
            throw error
        } catch {
            throw CircleSharingErrorMapping.map(error)
        }
    }

    func acceptPendingInvitation() async throws {
        guard let metadata = shareAcceptanceCoordinator.takePending() else {
            throw CircleSharingError.invitationAcceptanceFailed(message: "No pending invitation to accept.")
        }

        guard let sharedStore = container.persistentStoreCoordinator.persistentStores.first(where: {
            $0.configurationName == PersistenceController.sharedConfigurationName
        }) else {
            throw CircleSharingError.zoneUnavailable
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                container.acceptShareInvitations(from: [metadata], into: sharedStore) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            throw CircleSharingErrorMapping.map(error)
        }
    }

    static func fetchCircleEntity(circleID: UUID, context: NSManagedObjectContext) throws -> CircleEntity? {
        let request = CircleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", circleID as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
