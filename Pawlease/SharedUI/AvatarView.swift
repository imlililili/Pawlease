import SwiftUI

/// A circular member avatar showing initials on a deterministic color from
/// `PawleaseTheme.avatarColors` — the shared avatar treatment used on Pet
/// Home, Circle Settings, Circle Diary and My Archive. Purely presentational
/// formatting (initials/color derivation), not a business rule.
struct AvatarView: View {
    let name: String
    /// Any stable per-member identity string (a `profileID.uuidString` is
    /// ideal) used only to pick a consistent color — never displayed.
    let identitySeed: String
    var diameter: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Self.color(for: identitySeed))
            .frame(width: diameter, height: diameter)
            .overlay {
                Text(Self.initials(for: name))
                    .font(.system(size: diameter * 0.4, weight: .semibold))
                    .foregroundStyle(PawleaseTheme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityHidden(true)
            }
    }

    static func initials(for name: String) -> String {
        let words = name.split(separator: " ").filter { !$0.isEmpty }
        if words.count >= 2, let first = words[0].first, let second = words[1].first {
            return String([first, second]).uppercased()
        }
        if let word = words.first {
            return String(word.prefix(2)).uppercased()
        }
        return "?"
    }

    static func color(for identitySeed: String) -> Color {
        let hash = identitySeed.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let index = abs(hash) % PawleaseTheme.avatarColors.count
        return PawleaseTheme.avatarColors[index]
    }
}
