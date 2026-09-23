import Foundation

/// A framework-independent record of one photo the Share Extension has
/// staged in the App Group inbox, waiting for the main app to import it.
/// Written by the extension, read and removed by the main app — never a
/// `PendingPostDraftEntity` or any other Core Data type.
///
/// `imageFilename` is always a bare relative filename (never a path),
/// resolved safely through `ShareInboxStoring` — see that protocol's
/// path-traversal note.
struct PendingShareManifest: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let caption: String?
    let imageFilename: String
    let createdAt: Date
    let source: String
}

/// Identifies which extension produced a `PendingShareManifest`.
enum PendingShareSource {
    static let photosShareExtension = "photos-share-extension"
}

/// Shared validation limits so the Share Extension (which cannot link the
/// main app's Domain layer) and the main app agree on the same numbers
/// without duplicating a magic number in two places.
enum PendingShareLimits {
    static let maxCaptionLength = 60
}

enum ShareCaptionError: Error, Sendable, Equatable {
    case tooLong
}

/// Pure caption validation shared by the extension and unit tests. Trims
/// whitespace, maps an empty result to `nil`, and rejects anything over
/// `PendingShareLimits.maxCaptionLength`.
enum ShareCaptionValidation {
    static func validate(_ caption: String) -> Result<String?, ShareCaptionError> {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= PendingShareLimits.maxCaptionLength else {
            return .failure(.tooLong)
        }
        return .success(trimmed.isEmpty ? nil : trimmed)
    }
}
