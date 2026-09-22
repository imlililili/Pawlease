import Foundation

/// Orchestrates CloudKit sharing for a Circle. Implemented in the Data layer
/// using `NSPersistentCloudKitContainer`'s sharing APIs and `CKShare` —
/// none of that ever appears in this protocol's signatures.
///
/// `acceptPendingInvitation()` takes no parameters deliberately: the actual
/// `CKShare.Metadata` delivered by `application(_:userDidAcceptCloudKitShareWith:)`
/// is staged in a Data/Infrastructure-layer coordinator (never in Domain or
/// a ViewModel), and this method simply asks the repository to process
/// whatever invitation is currently staged.
protocol CircleSharingRepository: Sendable {
    func sharingState(circleID: UUID) async throws -> CircleSharingState
    @discardableResult
    func prepareShare(circleID: UUID) async throws -> PreparedCircleShare
    func acceptPendingInvitation() async throws
}
