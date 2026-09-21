import Foundation

/// A validated caption for a `DailyMoment`. Captions are limited to 60
/// characters so posts stay quick, low-effort, and skimmable.
struct MomentCaption: Sendable, Equatable, Hashable {
    static let maxLength = 60

    let value: String

    init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DomainValidationError.captionEmpty
        }
        guard trimmed.count <= Self.maxLength else {
            throw DomainValidationError.captionTooLong
        }
        self.value = trimmed
    }
}
