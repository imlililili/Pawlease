import Foundation
import UniformTypeIdentifiers

/// Pure validation of a share attachment, kept separate from the actual
/// image-data loading (which needs `UIImage`/UIKit and stays in the Share
/// Extension target) so it's unit testable from the main app's test target
/// via `@testable import Pawlease` — `SharedKit` compiles into both.
enum ShareAttachmentError: Error, Sendable, Equatable {
    case missingAttachment
    case unsupportedType
}

enum ShareAttachmentValidation {
    /// `NSItemProvider` is a plain Foundation type (not UIKit), so this can
    /// run — and be tested — without pulling in image decoding at all.
    static func validateImageProvider(_ itemProvider: NSItemProvider?) -> Result<NSItemProvider, ShareAttachmentError> {
        guard let itemProvider else {
            return .failure(.missingAttachment)
        }
        guard itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            return .failure(.unsupportedType)
        }
        return .success(itemProvider)
    }
}
