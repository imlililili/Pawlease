import Foundation
@testable import Pawlease

/// Configurable test double for `CircleSharingRepository`: stubbed
/// results, injectable errors, captured arguments, and invocation counts.
final class MockCircleSharingRepository: CircleSharingRepository, @unchecked Sendable {
    var sharingStateResult: CircleSharingState = .localOnly
    var sharingStateError: Error?
    private(set) var sharingStateCallCount = 0
    private(set) var sharingStateCapturedCircleIDs: [UUID] = []

    var prepareShareResult: PreparedCircleShare?
    var prepareShareError: Error?
    private(set) var prepareShareCallCount = 0
    private(set) var prepareShareCapturedCircleIDs: [UUID] = []

    var acceptPendingInvitationError: Error?
    var acceptPendingInvitationResult = AcceptedCircleHandoff(circleID: nil)
    private(set) var acceptPendingInvitationCallCount = 0

    func sharingState(circleID: UUID) async throws -> CircleSharingState {
        sharingStateCallCount += 1
        sharingStateCapturedCircleIDs.append(circleID)
        if let sharingStateError { throw sharingStateError }
        return sharingStateResult
    }

    @discardableResult
    func prepareShare(circleID: UUID) async throws -> PreparedCircleShare {
        prepareShareCallCount += 1
        prepareShareCapturedCircleIDs.append(circleID)
        if let prepareShareError { throw prepareShareError }
        return prepareShareResult ?? PreparedCircleShare(circleID: circleID, isNewShare: true)
    }

    @discardableResult
    func acceptPendingInvitation() async throws -> AcceptedCircleHandoff {
        acceptPendingInvitationCallCount += 1
        if let acceptPendingInvitationError { throw acceptPendingInvitationError }
        return acceptPendingInvitationResult
    }
}
