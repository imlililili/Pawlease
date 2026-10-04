import Foundation

/// Presentation-ready, pre-formatted state for the Pet Home screen, derived
/// once from a `PetHomeSnapshot` so the View stays free of formatting logic.
struct PetHomeViewState: Equatable {
    let circleName: String
    let petName: String
    let petStage: PetLifeStage
    let activityStateLabel: String
    /// e.g. "Thriving" / "Resting" paired with a checkmark — the status
    /// pill overlaid on the pet artwork's upper-left corner.
    let hasSurvivedToday: Bool
    /// e.g. "1/2 today" — the pill overlaid on the pet artwork's lower-right
    /// corner.
    let contributorPillLabel: String
    let progressLabel: String
    let contributorAccessibilityLabel: String
    let statusExplanation: String
    let streakDays: Int
    let streakLabel: String
    let hasPosted: Bool
    let canViewFeed: Bool

    init(snapshot: PetHomeSnapshot) {
        circleName = snapshot.circle.name
        petName = snapshot.pet.name
        petStage = snapshot.pet.stage
        activityStateLabel = snapshot.activityState.displayName
        hasSurvivedToday = snapshot.careStatus.hasSurvived
        contributorPillLabel = "\(snapshot.careStatus.contributorCount)/\(snapshot.careStatus.requiredContributorCount) today"
        progressLabel = "\(snapshot.careStatus.contributorCount) of \(snapshot.careStatus.requiredContributorCount)"
        contributorAccessibilityLabel = "\(snapshot.careStatus.contributorCount) of \(snapshot.careStatus.requiredContributorCount) friends have shared today"
        streakDays = snapshot.currentStreak
        streakLabel = snapshot.currentStreak > 0 ? "\(snapshot.currentStreak) days" : "No streak yet"
        hasPosted = snapshot.hasCurrentMemberPosted
        canViewFeed = snapshot.canViewTodayFeed

        let remaining = max(0, snapshot.careStatus.requiredContributorCount - snapshot.careStatus.contributorCount)
        if snapshot.careStatus.hasSurvived {
            statusExplanation = "Safe today · \(snapshot.pet.name) is thriving thanks to \(snapshot.careStatus.contributorCount) friends."
        } else if remaining == 1 {
            statusExplanation = "Safe today · one more friend keeps \(snapshot.pet.name) thriving."
        } else {
            statusExplanation = "\(remaining) more friends keep \(snapshot.pet.name) thriving today."
        }
    }
}
