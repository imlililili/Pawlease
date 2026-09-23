import UIKit

/// Builds the native `UICloudSharingController` for a Circle. This lives in
/// Infrastructure, not Domain, because `UICloudSharingController` and
/// `CKShare` are framework-specific — Domain and Application never see
/// them. A View (not a ViewModel) holds this provider and presents the
/// controller it returns; the ViewModel only ever sees the Domain-safe
/// `CloudSharingOutcome` reported back through a delegate callback.
protocol CloudSharingControllerProviding: AnyObject {
    @MainActor
    func makeSharingController(circleID: UUID, onOutcome: @escaping (CloudSharingOutcome) -> Void) async throws -> UICloudSharingController
}
