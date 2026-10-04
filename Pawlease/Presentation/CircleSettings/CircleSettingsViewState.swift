import Foundation

/// Presentation-ready, pre-formatted state for the Circle Settings screen.
struct CircleSettingsViewState: Equatable {
    struct MemberItem: Equatable, Identifiable {
        let id: UUID
        let displayName: String
        let roleLabel: String
        let isOwner: Bool
        /// A stable per-member seed for `AvatarView`'s color — the
        /// member's own `profileID`, not the row's own `id`, so a
        /// member's avatar color stays the same wherever else they're
        /// shown (Pet Home, Circle Diary).
        let avatarSeed: String
    }

    let circleName: String
    let petName: String
    /// e.g. "America / Los Angeles" — `timezoneIdentifier` reformatted for
    /// display, never parsed back.
    let timeZoneLabel: String
    let members: [MemberItem]
    let memberCountLabel: String
    let accountStatusLabel: String
    let sharingStateLabel: String
    let canInvite: Bool
    let inviteButtonLabel: String
    let lastUpdatedLabel: String?

    init(
        circleName: String,
        petName: String,
        timezoneIdentifier: String,
        members: [CircleMember],
        accountAvailability: CloudAccountAvailability,
        sharingState: CircleSharingState,
        lastUpdatedAt: Date?
    ) {
        self.circleName = circleName
        self.petName = petName
        self.timeZoneLabel = timezoneIdentifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "/", with: " / ")
        self.members = members.map { member in
            MemberItem(
                id: member.id,
                displayName: member.displayName,
                roleLabel: member.role == .owner ? "Owner" : "Member",
                isOwner: member.role == .owner,
                avatarSeed: member.profileID.uuidString
            )
        }
        self.memberCountLabel = "MEMBERS · \(members.count) OF 5"
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
