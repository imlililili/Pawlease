import Foundation

/// A validated single-level comment body. Comments are limited to 60
/// characters, mirroring `MomentCaption`, so replies stay quick and skimmable.
struct CommentBody: Sendable, Equatable, Hashable {
    static let maxLength = 60

    let value: String

    init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DomainValidationError.commentEmpty
        }
        guard trimmed.count <= Self.maxLength else {
            throw DomainValidationError.commentTooLong
        }
        self.value = trimmed
    }
}
