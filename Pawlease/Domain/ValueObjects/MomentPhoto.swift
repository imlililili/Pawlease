import Foundation

/// A processed photo attached to a `DailyMoment`: a display-sized image plus
/// a lightweight thumbnail for feed rows. Holds raw bytes only — no
/// UIKit/AppKit image types belong in the Domain layer.
struct MomentPhoto: Sendable, Equatable {
    let imageData: Data
    let thumbnailData: Data

    init(imageData: Data, thumbnailData: Data) throws {
        guard !imageData.isEmpty, !thumbnailData.isEmpty else {
            throw DomainValidationError.emptyPhotoData
        }
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }
}
