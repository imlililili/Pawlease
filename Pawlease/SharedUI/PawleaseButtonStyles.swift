import SwiftUI

/// The rounded-rectangle, orange-filled primary button used across every
/// screen (Today's Moment, New Diary Entry, Publish, Share Today's Moment,
/// Create Invite Code, …) — one shared style instead of repeating the same
/// fill/corner-radius/disabled-opacity everywhere.
struct PawleasePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .background(
                isEnabled ? PawleaseTheme.accentPrimary : PawleaseTheme.accentPrimaryDisabled,
                in: RoundedRectangle(cornerRadius: PawleaseTheme.buttonCornerRadius)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// A neutral, outlined rounded-rectangle button — Cancel actions, and other
/// secondary controls that sit beside a primary button.
struct PawleaseSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(PawleaseTheme.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: PawleaseTheme.buttonCornerRadius)
                    .stroke(PawleaseTheme.divider, lineWidth: 1)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.5)
    }
}

/// A compact selectable pill — used for the Diary composer's four
/// visibility options. Filled orange when selected, outlined when not.
struct PawleaseSelectablePillButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : PawleaseTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: PawleaseTheme.buttonCornerRadius)
                    .fill(isSelected ? PawleaseTheme.accentPrimary : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PawleaseTheme.buttonCornerRadius)
                    .stroke(isSelected ? Color.clear : PawleaseTheme.divider, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
