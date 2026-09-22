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

    var saveMomentResult: DailyMoment?
    var saveMomentError: Error?
    private(set) var saveMomentCallCount = 0
    private(set) var savedMoments: [DailyMoment] = []

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
        hasMemberPostedResult
    }

    @discardableResult
    func saveMoment(_ moment: DailyMoment) async throws -> DailyMoment {
        saveMomentCallCount += 1
        savedMoments.append(moment)
        if let saveMomentError { throw saveMomentError }
        return saveMomentResult ?? moment
    }
}
