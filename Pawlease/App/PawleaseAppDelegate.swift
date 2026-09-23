import CloudKit
import UIKit

/// Receives CloudKit share invitation acceptance from the system and
/// forwards it to `ShareAcceptanceCoordinator` — no acceptance business
/// logic lives here. `AcceptCircleInvitationUseCase` (invoked from
/// Presentation once the app is foregrounded) does the actual import.
final class PawleaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        ShareAcceptanceCoordinator.shared.stage(cloudKitShareMetadata)
    }
}
