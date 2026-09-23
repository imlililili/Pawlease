import Foundation

/// Presentation-ready, pre-formatted state for the Circle Settings screen.
struct CircleSettingsViewState: Equatable {
    let circleName: String
    let petName: String
    let memberNames: [String]
    let accountStatusLabel: String
    let sharingStateLabel: String
    let canInvite: Bool
    let inviteButtonLabel: String
    let lastUpdatedLabel: String?

    init(
        circleName: String,
        petName: String,
        memberNames: [String],
        accountAvailability: CloudAccountAvailability,
        sharingState: CircleSharingState,
        lastUpdatedAt: Date?
    ) {
        self.circleName = circleName
        self.petName = petName
        self.memberNames = memberNames
        self.accountStatusLabel = accountAvailability.displayName
        self.sharingStateLabel = sharingState.displayName
        self.canInvite = accountAvailability.allowsSharing && sharingState != .preparing
        self.inviteButtonLabel = (sharingState == .shared) ? "Invite More Friends" : "Invite Friends"

        if let lastUpdatedAt {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            self.lastUpdatedLabel = "Last updated \(formatter.string(from: lastUpdatedAt))"
        } else {
            self.lastUpdatedLabel = nil
        }
    }
}
