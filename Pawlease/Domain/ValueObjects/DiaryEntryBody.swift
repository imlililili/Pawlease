import Foundation

/// A validated Circle Diary entry body. Diary entries are text-only and are
/// limited to 500 characters — long enough for a real thought, short enough
/// to stay skimmable in a private feed.
struct DiaryEntryBody: Sendable, Equatable, Hashable {
    static let maxLength = 500

    let value: String

    init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DomainValidationError.diaryBodyEmpty
        }
        guard trimmed.count <= Self.maxLength else {
            throw DomainValidationError.diaryBodyTooLong
        }
        self.value = trimmed
    }
}
