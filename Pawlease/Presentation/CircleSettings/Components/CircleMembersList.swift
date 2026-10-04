import SwiftUI

/// The "MEMBERS · X OF 5" roster: avatar initials, display name, role, and
/// an Owner badge for the Circle's owner.
struct CircleMembersList: View {
    let members: [CircleSettingsViewState.MemberItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(members) { member in
                memberRow(member)
                if member.id != members.last?.id {
                    Rectangle()
                        .fill(PawleaseTheme.divider)
                        .frame(height: 1)
                }
            }
        }
    }

    private func memberRow(_ member: CircleSettingsViewState.MemberItem) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: member.displayName, identitySeed: member.avatarSeed, diameter: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text(member.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PawleaseTheme.textPrimary)
                Text(member.roleLabel)
                    .font(.subheadline)
                    .foregroundStyle(PawleaseTheme.textSecondary)
            }

            Spacer()

            if member.isOwner {
                Text("Owner")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PawleaseTheme.accentPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(PawleaseTheme.accentSecondaryFill, in: Capsule())
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.displayName), \(member.roleLabel)\(member.isOwner ? ", Circle owner" : "")")
    }
}
