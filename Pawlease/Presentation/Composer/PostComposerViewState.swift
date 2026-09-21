import Foundation

/// Pre-formatted display state for the caption field, derived from the raw
/// caption text so the View doesn't do its own string math.
struct PostComposerViewState: Equatable {
    let characterCountLabel: String
    let isCaptionValid: Bool

    init(captionText: String, limit: Int) {
        characterCountLabel = "\(captionText.count)/\(limit)"
        let trimmed = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        isCaptionValid = !trimmed.isEmpty && captionText.count <= limit
    }
}
