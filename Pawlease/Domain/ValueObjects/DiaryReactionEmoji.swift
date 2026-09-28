import Foundation

/// One free-form emoji reaction on a Circle Diary entry or comment, typed
/// directly from the system emoji keyboard — deliberately not the fixed
/// `ReactionEmoji` set used by Daily Moments. Validates that the trimmed
/// input is exactly one user-perceived character (an extended grapheme
/// cluster — `String.count`/`Character` already count graphemes, so a
/// multi-scalar sequence like a ZWJ family emoji or a flag still counts as
/// one) and that it actually is an emoji rather than an ordinary letter,
/// digit, or symbol.
///
/// Validated via `Unicode.Scalar.Properties` (the documented public API for
/// Unicode's emoji-data properties — there is no `Character.isEmoji` in the
/// standard library): at least one of the character's scalars must be
/// `isEmoji`, and — since Swift's Unicode data marks plain ASCII digits and
/// `#`/`*` as `isEmoji` too (they double as the base of a keycap sequence
/// like `3️⃣`) — either the character is a multi-scalar sequence (a ZWJ
/// sequence, a flag, or an emoji+variation-selector pair) or its scalar is
/// `isEmojiPresentation` (true by default for genuine pictographic emoji,
/// false for a bare digit/`#`/`*` typed without the variation selector the
/// system keyboard always attaches). That combination excludes the
/// bare-digit false positive while accepting everything the system emoji
/// keyboard can actually produce.
struct DiaryReactionEmoji: Sendable, Equatable, Hashable {
    let value: String

    init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let character = trimmed.first, trimmed.count == 1 else {
            throw DomainValidationError.invalidDiaryReactionEmoji
        }
        let scalars = character.unicodeScalars
        let hasEmojiScalar = scalars.contains { $0.properties.isEmoji }
        let hasEmojiPresentation = scalars.count > 1 || scalars.first?.properties.isEmojiPresentation == true
        guard hasEmojiScalar && hasEmojiPresentation else {
            throw DomainValidationError.invalidDiaryReactionEmoji
        }
        self.value = String(character)
    }
}
