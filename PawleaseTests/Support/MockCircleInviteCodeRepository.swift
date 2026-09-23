import Foundation
@testable import Pawlease

/// Configurable test double for `CircleInviteCodeRepository`: stubbed
/// results, injectable errors, captured arguments, and invocation counts.
/// Never touches real CloudKit — used by Use Case tests only.
final class MockCircleInviteCodeRepository: CircleInviteCodeRepository, @unchecked Sendable {
    /// Queue of results `publish(_:)` returns, one per call — lets a test
    /// simulate "collision, then collision, then success" for the retry
    /// loop. If the queue runs out, the last published `details` argument
    /// is echoed back.
    var publishResultQueue: [Result<CircleInviteCodeDetails, Error>] = []
    private(set) var publishCallCount = 0
    private(set) var publishedDetails: [CircleInviteCodeDetails] = []

    var fetchActiveCodeResult: CircleInviteCodeDetails?
    var fetchActiveCodeError: Error?
    private(set) var fetchActiveCodeCallCount = 0
    private(set) var fetchActiveCodeCapturedCircleIDs: [UUID] = []

    var fetchCodeResult: CircleInviteCodeDetails?
    var fetchCodeError: Error?
    private(set) var fetchCodeCallCount = 0
    private(set) var fetchCodeCapturedCodes: [CircleInviteCode] = []

    var revokeError: Error?
    private(set) var revokeCallCount = 0
    private(set) var revokedCodes: [CircleInviteCode] = []

    @discardableResult
    func publish(_ details: CircleInviteCodeDetails) async throws -> CircleInviteCodeDetails {
        publishCallCount += 1
        publishedDetails.append(details)
        guard !publishResultQueue.isEmpty else { return details }
        let result = publishResultQueue.removeFirst()
        return try result.get()
    }

    func fetchActiveCode(circleID: UUID) async throws -> CircleInviteCodeDetails? {
        fetchActiveCodeCallCount += 1
        fetchActiveCodeCapturedCircleIDs.append(circleID)
        if let fetchActiveCodeError { throw fetchActiveCodeError }
        return fetchActiveCodeResult
    }

    func fetchCode(_ code: CircleInviteCode) async throws -> CircleInviteCodeDetails {
        fetchCodeCallCount += 1
        fetchCodeCapturedCodes.append(code)
        if let fetchCodeError { throw fetchCodeError }
        guard let fetchCodeResult else { throw CircleInviteCodeError.notFound }
        return fetchCodeResult
    }

    func revoke(_ code: CircleInviteCode) async throws {
        revokeCallCount += 1
        revokedCodes.append(code)
        if let revokeError { throw revokeError }
    }
}
