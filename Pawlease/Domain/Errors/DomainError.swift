import Foundation

/// Validation failures for Domain value objects. These are pure, input-driven
/// errors independent of persistence or network state.
enum DomainValidationError: Error, Equatable, Sendable {
    case captionTooLong
    case captionEmpty
    case emptyPhotoData
    case commentTooLong
    case commentEmpty
    case invalidReactionEmoji
    case diaryBodyTooLong
    case diaryBodyEmpty
    case invalidDiaryReactionEmoji
}

/// Failures surfaced while orchestrating Use Cases. These represent Circle
/// state or workflow conditions rather than raw persistence failures.
enum DomainError: Error, Equatable, Sendable {
    case circleNotFound
    case memberNotFound
    case petNotFound
    case feedLocked
    case momentNotFound
    case commentNotFound
    case notCommentAuthor
    /// A `PendingPostDraftEntity` row is missing required fields (id,
    /// image path, or source) — the record can't be represented as a
    /// `PendingPostDraft`.
    case pendingDraftCorrupted
    /// Joining would exceed the Circle's maximum member count.
    case membershipFull
    case diaryEntryNotFound
    case notDiaryEntryAuthor
    case diaryCommentNotFound
    /// A `DiaryEntryEntity` row has a `visibilityDuration` that doesn't
    /// match any `DiaryVisibilityDuration` case — the record can't be
    /// represented as a `DiaryEntry`.
    case diaryEntryCorrupted
}
