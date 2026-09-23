import CloudKit
import CoreData
import UIKit

/// Builds the native `UICloudSharingController` for a Circle — reusing an
/// existing `CKShare` when one exists, or lazily creating one via the
/// controller's own preparation handler otherwise. Outcomes (saved, stopped
/// sharing, failed) are reported back through `onOutcome` as Domain-safe
/// `CloudSharingOutcome` values, never as raw `CKError`.
final class CloudKitSharingControllerProvider: NSObject, CloudSharingControllerProviding {
    private let container: NSPersistentCloudKitContainer
    private var onOutcome: ((CloudSharingOutcome) -> Void)?

    init(container: NSPersistentCloudKitContainer) {
        self.container = container
    }

    @MainActor
    func makeSharingController(
        circleID: UUID,
        onOutcome: @escaping (CloudSharingOutcome) -> Void
    ) async throws -> UICloudSharingController {
        let context = container.viewContext
        let entity = try context.performAndWait { () -> CircleEntity in
            guard let entity = try CloudKitCircleSharingRepository.fetchCircleEntity(circleID: circleID, context: context) else {
                throw CircleSharingError.circleNotFound
            }
            return entity
        }

        let existingShares = try context.performAndWait {
            try container.fetchShares(matching: [entity.objectID])
        }

        self.onOutcome = onOutcome

        let controller: UICloudSharingController
        if let existingShare = existingShares[entity.objectID] {
            controller = UICloudSharingController(
                share: existingShare,
                container: CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier)
            )
        } else {
            controller = UICloudSharingController { [weak self] _, completion in
                guard let self else { return }
                Task {
                    do {
                        let (_, share, ckContainer) = try await self.container.share([entity], to: nil)
                        share[CKShare.SystemFieldKey.title] = "Pawlease Circle" as CKRecordValue
                        completion(share, ckContainer, nil)
                    } catch {
                        completion(nil, nil, error)
                    }
                }
            }
        }

        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = self
        return controller
    }
}

extension CloudKitSharingControllerProvider: UICloudSharingControllerDelegate {
    func itemTitle(for csc: UICloudSharingController) -> String? {
        "Pawlease Circle"
    }

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        onOutcome?(.failed(CircleSharingErrorMapping.map(error)))
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        onOutcome?(.saved)
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        onOutcome?(.stoppedSharing)
    }
}
