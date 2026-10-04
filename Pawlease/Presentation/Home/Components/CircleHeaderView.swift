import SwiftUI

/// Pet Home's top section: the "YOUR CIRCLE" eyebrow, the Circle's name, and
/// an overlapping stack of member avatars aligned to the trailing edge.
struct CircleHeaderView: View {
    let circleName: String
    let members: [CircleMember]

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR CIRCLE")
                    .font(.caption.weight(.semibold))
                    .tracking(0.6)
                    .foregroundStyle(PawleaseTheme.textSecondary)
                Text(circleName)
                    .font(.title2.bold())
                    .foregroundStyle(PawleaseTheme.textPrimary)
            }
            Spacer(minLength: 12)
            avatarStack
        }
        .accessibilityElement(children: .combine)
    }

    private var avatarStack: some View {
        HStack(spacing: -12) {
            ForEach(members) { member in
                AvatarView(name: member.displayName, identitySeed: member.profileID.uuidString, diameter: 36)
                    .overlay(Circle().stroke(PawleaseTheme.background, lineWidth: 2))
            }
        }
        .accessibilityLabel("Circle members: \(members.map(\.displayName).joined(separator: ", "))")
    }
}
