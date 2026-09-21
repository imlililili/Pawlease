import Foundation

/// Presentation-ready, pre-formatted state for the Pet Home screen, derived
/// once from a `PetHomeSnapshot` so the View stays free of formatting logic.
struct PetHomeViewState: Equatable {
    let petName: String
    let petStage: PetLifeStage
    let activityStateLabel: String
    let progressLabel: String
    let contributorAccessibilityLabel: String
    let streakLabel: String
    let hasPosted: Bool
    let canViewFeed: Bool

    init(snapshot: PetHomeSnapshot) {
        petName = snapshot.pet.name
        petStage = snapshot.pet.stage
        activityStateLabel = snapshot.activityState.displayName
        progressLabel = "\(snapshot.careStatus.contributorCount)/\(snapshot.careStatus.requiredContributorCount)"
        contributorAccessibilityLabel = "\(snapshot.careStatus.contributorCount) of \(snapshot.careStatus.requiredContributorCount) friends have shared today"
        streakLabel = snapshot.currentStreak > 0 ? "\(snapshot.currentStreak)-day streak" : "No streak yet"
        hasPosted = snapshot.hasCurrentMemberPosted
        canViewFeed = snapshot.canViewTodayFeed
    }
}
