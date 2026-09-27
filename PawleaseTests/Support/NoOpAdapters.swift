import Foundation
import UIKit
@testable import Pawlease

/// Trivial no-op stand-ins for Infrastructure-layer protocols that a
/// `PetHomeViewModel` test needs to construct a real instance with, but
/// whose behavior is irrelevant to the test in question (e.g. a
/// concurrency regression test that only cares about seeded Member state).

final class NoOpRemoteChangeSignal: RemoteChangeSignaling {
    func remoteChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in continuation.finish() }
    }
}

final class NoOpCloudSyncEventSignal: CloudSyncEventSignaling {
    func syncEvents() -> AsyncStream<CircleSyncStatus> {
        AsyncStream { continuation in continuation.finish() }
    }
}

final class NoOpShareURLOpener: ShareURLOpening {
    func open(_ url: URL) async -> Bool { false }
}

/// Never actually invoked by `PetHomeViewModel` itself — it only ever holds
/// this to forward to `CircleSettingsView` — so throwing immediately is
/// sufficient without needing to construct a real `UICloudSharingController`.
final class NoOpCloudSharingControllerProvider: CloudSharingControllerProviding {
    func makeSharingController(
        circleID: UUID,
        onOutcome: @escaping (CloudSharingOutcome) -> Void
    ) async throws -> UICloudSharingController {
        throw CircleSharingError.circleNotFound
    }
}
