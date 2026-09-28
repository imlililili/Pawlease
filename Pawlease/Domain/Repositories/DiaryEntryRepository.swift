import Foundation

/// Persists and retrieves `DiaryEntry` records. Deletion is always soft:
/// the record is retained with `isDeleted = true` rather than erased, so
/// CloudKit synchronization can never resurrect deleted content and an
/// archived entry's comments/reactions stay intact.
///
/// Fetches return *every* entry for a Circle (or author), active or not —
/// filtering by expiry/deletion is a Use Case concern (`isExpired`/
/// `isActive` are always recalculated from the injected clock), never a
/// repository-level concern.
protocol DiaryEntryRepository: Sendable {
    func fetchEntries(circleID: UUID) async throws -> [DiaryEntry]
    func fetchEntry(entryID: UUID) async throws -> DiaryEntry?
    @discardableResult
    func saveEntry(_ entry: DiaryEntry) async throws -> DiaryEntry
    func softDeleteEntry(entryID: UUID, requestingProfileID: UUID, deletedAt: Date) async throws
}
