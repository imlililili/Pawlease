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
}
