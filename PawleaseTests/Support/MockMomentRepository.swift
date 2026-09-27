import Foundation
@testable import Pawlease

/// Configurable test double for `MomentRepository`: stubbed results,
/// injectable errors, captured arguments, and invocation counts — for
/// asserting exactly how a Use Case talks to the repository, not just what
/// it returns.
final class MockMomentRepository: MomentRepository, @unchecked Sendable {
    var fetchMomentResult: DailyMoment?
    var fetchMomentError: Error?
    private(set) var fetchMomentCallCount = 0
    private(set) var fetchMomentCapturedIDs: [UUID] = []

    var fetchMomentsByDayResult: [DailyMoment] = []
    var fetchMomentsByDaysResult: [DailyMoment] = []
    var hasMemberPostedResult = false
    /// Overrides `hasMemberPostedResult` when set — lets a test distinguish
    /// between two different profile IDs (e.g. "the current member has
    /// posted, but the demo friend hasn't") instead of one flat answer for
    /// every call.
    var hasMemberPostedHandler: ((_ circleID: UUID, _ profileID: UUID, _ day: CircleDay) -> Bool)?

    var saveMomentResult: DailyMoment?
    var saveMomentError: Error?
    private(set) var saveMomentCallCount = 0
    private(set) var savedMoments: [DailyMoment] = []

    var deleteMomentsError: Error?
    private(set) var deleteMomentsCallCount = 0
    private(set) var deleteMomentsCapturedArgs: [(circleID: UUID, authorProfileID: UUID)] = []

    func fetchMoment(id: UUID) async throws -> DailyMoment? {
        fetchMomentCallCount += 1
        fetchMomentCapturedIDs.append(id)
        if let fetchMomentError { throw fetchMomentError }
        return fetchMomentResult
    }

    func fetchMoments(circleID: UUID, day: CircleDay) async throws -> [DailyMoment] {
        fetchMomentsByDayResult
    }

    func fetchMoments(circleID: UUID, days: [CircleDay]) async throws -> [DailyMoment] {
        fetchMomentsByDaysResult
    }

    func hasMemberPosted(circleID: UUID, profileID: UUID, day: CircleDay) async throws -> Bool {
        if let hasMemberPostedHandler {
            return hasMemberPostedHandler(circleID, profileID, day)
        }
        return hasMemberPostedResult
    }

    @discardableResult
    func saveMoment(_ moment: DailyMoment) async throws -> DailyMoment {
        saveMomentCallCount += 1
        savedMoments.append(moment)
        if let saveMomentError { throw saveMomentError }
        return saveMomentResult ?? moment
    }

    func deleteMoments(circleID: UUID, authorProfileID: UUID) async throws {
        deleteMomentsCallCount += 1
        deleteMomentsCapturedArgs.append((circleID, authorProfileID))
        if let deleteMomentsError { throw deleteMomentsError }
    }
}
