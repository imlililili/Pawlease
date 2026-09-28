import Foundation

/// One text-only Circle Diary post. Diary entries are a distinct product
/// surface from `DailyMoment`: they never require a photo, never count
/// toward the pet's 2-of-2 survival rule, and can be timed to disappear
/// from the shared feed.
///
/// `isExpired`/`isActive` are deliberately *not* stored fields — expiry is
/// always recalculated from `createdAt`, `expiresAt`, `isDeleted`, and an
/// injected clock, so no mutable "expired" flag can ever drift out of sync
/// or need a background job to flip it.
struct DiaryEntry: Identifiable, Sendable, Equatable {
    let id: UUID
    let circleID: UUID
    let authorProfileID: UUID
    let authorNameSnapshot: String
    let authorAvatarSnapshot: String
    let body: DiaryEntryBody
    let visibilityDuration: DiaryVisibilityDuration
    let createdAt: Date
    /// `nil` for a permanent entry. For a timed entry, the exact instant
    /// `createdAt + visibilityDuration.expiryHours` — computed once at
    /// publish time so it never has to be recomputed from a possibly-edited
    /// `visibilityDuration` later (entries are never edited).
    let expiresAt: Date?
    let isDeleted: Bool
    let deletedAt: Date?

    /// Whether this entry's visibility window has passed as of `now`.
    /// Always `false` for a permanent entry (`expiresAt == nil`).
    func isExpired(asOf now: Date) -> Bool {
        guard let expiresAt else { return false }
        return now >= expiresAt
    }

    /// Whether this entry currently belongs in the shared Circle feed: not
    /// soft-deleted and not expired.
    func isActive(asOf now: Date) -> Bool {
        !isDeleted && !isExpired(asOf: now)
    }
}
