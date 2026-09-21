import Foundation

/// Derives a Circle day's `DailyCareStatus` from the moments posted that
/// day. Multiple posts from the same author still count as one contributor;
/// at least two distinct contributors are required to survive the day.
struct CalculateDailyCareStatusUseCase: Sendable {
    static let requiredContributorCount = 2

    func execute(moments: [DailyMoment]) -> DailyCareStatus {
        let contributorIDs = Set(moments.map(\.authorProfileID))
        return DailyCareStatus(
            requiredContributorCount: Self.requiredContributorCount,
            contributorIDs: contributorIDs
        )
    }
}
