import UIKit

/// Normalizes orientation and produces a display-sized image plus a
/// thumbnail, ready to become a `MomentPhoto`. Lives in Infrastructure (not
/// Domain) because it depends on UIKit.
struct PhotoProcessingService: Sendable {
    enum ProcessingError: Error {
        case invalidImageData
    }

    private let maxImageDimension: CGFloat = 1200
    private let maxThumbnailDimension: CGFloat = 300
    private let jpegQuality: CGFloat = 0.7

    func process(_ data: Data) throws -> MomentPhoto {
        guard let image = UIImage(data: data) else {
            throw ProcessingError.invalidImageData
        }

        let normalized = image.normalizedOrientation()

        guard
            let mainData = normalized.resized(maxDimension: maxImageDimension).jpegData(compressionQuality: jpegQuality),
            let thumbnailData = normalized.resized(maxDimension: maxThumbnailDimension).jpegData(compressionQuality: jpegQuality)
        else {
            throw ProcessingError.invalidImageData
        }

        return try MomentPhoto(imageData: mainData, thumbnailData: thumbnailData)
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resized(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension, largestSide > 0 else { return self }
        let scaleFactor = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
