import SwiftUI
import UIKit

/// Shared visual tokens for the approved Pawlease design: warm cream
/// background, orange accent, dark charcoal / warm gray text, thin warm-gray
/// dividers, and the standard spacing/corner-radius values every screen
/// reuses instead of repeating literal colors and numbers. Colors adapt for
/// Dark Mode (no reference was supplied for it, so this keeps the same warm
/// character rather than switching to a generic system palette).
enum PawleaseTheme {
    static let background = Color(light: UIColor(red: 0.965, green: 0.945, blue: 0.914, alpha: 1), dark: UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1))
    static let cardBackground = Color(light: UIColor(red: 0.984, green: 0.973, blue: 0.957, alpha: 1), dark: UIColor(red: 0.16, green: 0.15, blue: 0.14, alpha: 1))

    static let accentPrimary = Color(light: UIColor(red: 0.855, green: 0.549, blue: 0.267, alpha: 1), dark: UIColor(red: 0.918, green: 0.612, blue: 0.314, alpha: 1))
    static let accentPrimaryDisabled = accentPrimary.opacity(0.45)
    /// Light, tinted fill used for badges like the Owner pill — never the
    /// only way a state is communicated (always paired with text).
    static let accentSecondaryFill = accentPrimary.opacity(0.18)

    static let textPrimary = Color(light: UIColor(red: 0.145, green: 0.129, blue: 0.11, alpha: 1), dark: UIColor(red: 0.94, green: 0.93, blue: 0.90, alpha: 1))
    static let textSecondary = Color(light: UIColor(red: 0.51, green: 0.475, blue: 0.427, alpha: 1), dark: UIColor(red: 0.68, green: 0.65, blue: 0.61, alpha: 1))
    static let divider = Color(light: UIColor(red: 0.83, green: 0.80, blue: 0.75, alpha: 1), dark: UIColor(red: 0.30, green: 0.28, blue: 0.26, alpha: 1))

    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let buttonCornerRadius: CGFloat = 16
    static let cardCornerRadius: CGFloat = 24

    /// Deterministic per-member palette for `AvatarView` — cycled by a
    /// stable hash of the member's identity, never by random/appearance
    /// order, so one person's avatar color stays the same across screens
    /// and launches.
    static let avatarColors: [Color] = [
        Color(light: UIColor(red: 0.855, green: 0.549, blue: 0.267, alpha: 1), dark: UIColor(red: 0.918, green: 0.612, blue: 0.314, alpha: 1)),
        Color(light: UIColor(red: 0.663, green: 0.741, blue: 0.584, alpha: 1), dark: UIColor(red: 0.55, green: 0.63, blue: 0.48, alpha: 1)),
        Color(light: UIColor(red: 0.624, green: 0.757, blue: 0.831, alpha: 1), dark: UIColor(red: 0.42, green: 0.55, blue: 0.62, alpha: 1)),
        Color(light: UIColor(red: 0.886, green: 0.686, blue: 0.690, alpha: 1), dark: UIColor(red: 0.70, green: 0.46, blue: 0.47, alpha: 1))
    ]

    /// Placeholder pet-artwork background — the app has no stored pet photo,
    /// so `PetArtworkView` fills this with a large species emoji instead.
    static let petArtworkBackground = Color(light: UIColor(red: 0.902, green: 0.859, blue: 0.792, alpha: 1), dark: UIColor(red: 0.22, green: 0.20, blue: 0.17, alpha: 1))
}

/// Preserves the pre-redesign name for the one call site (`PetArtworkView`)
/// that predates `PawleaseTheme` — avoids a churny rename of an unrelated
/// file.
enum Theme {
    static let petArtworkBackground = PawleaseTheme.petArtworkBackground
}

extension Color {
    /// A color that resolves differently in light vs. dark appearance,
    /// without needing an Asset Catalog color set for every token.
    init(light: UIColor, dark: UIColor) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
