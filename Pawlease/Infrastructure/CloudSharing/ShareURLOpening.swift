import Foundation

/// Opens a resolved CKShare URL through the system, which is what actually
/// triggers Apple's native CKShare acceptance flow
/// (`application(_:userDidAcceptCloudKitShareWith:)`) — the same mechanism
/// already used for invitations sent from `UICloudSharingController`. Lives
/// in Infrastructure, not Domain or Application: `ResolveCircleInviteCodeUseCase`
/// only ever produces a `URL`, and never imports UIKit itself. A ViewModel
/// (Presentation) holds this adapter, not a Use Case.
protocol ShareURLOpening: Sendable {
    @MainActor
    func open(_ url: URL) async -> Bool
}
