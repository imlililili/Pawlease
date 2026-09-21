import Foundation

/// Whether a Circle day has enough distinct contributors for the pet to
/// survive. Always derived from the set of authors who posted that day —
/// never a stored, mutable counter — so multiple devices can never disagree
/// or double-increment it.
struct DailyCareStatus: Sendable, Equatable {
    let requiredContributorCount: Int
    let contributorIDs: Set<UUID>

    var contributorCount: Int {
        contributorIDs.count
    }

    var hasSurvived: Bool {
        contributorCount >= requiredContributorCount
    }
}
