import Foundation

/// An optional-in-practice caption for a `DailyMoment`. Core Data keeps the
/// value as a non-optional string for CloudKit compatibility, so no caption is
/// represented by an empty string.
struct MomentCaption: Sendable, Equatable, Hashable {
    static let maxLength = 60

    let value: String

    init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= Self.maxLength else {
            throw DomainValidationError.captionTooLong
        }
        self.value = trimmed
    }
}
