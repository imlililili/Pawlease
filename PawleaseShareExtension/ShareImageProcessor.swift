import UIKit

/// Normalizes orientation, resizes to ~1200px max dimension, and encodes
/// JPEG at ~0.7 quality — mirrors the main app's `PhotoProcessingService`,
/// but lives independently here (no thumbnail generation; the main app
/// regenerates both main and thumbnail images from this file when the
/// draft is actually published) since this target doesn't link the main
/// app's Infrastructure code.
struct ShareImageProcessor: Sendable {
    enum ProcessingError: Error {
        case invalidImageData
    }

    private let maxDimension: CGFloat = 1200
    private let jpegQuality: CGFloat = 0.7

    func process(_ data: Data) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw ProcessingError.invalidImageData
        }

        let normalized = image.normalizedOrientation()
        guard let jpegData = normalized.resized(maxDimension: maxDimension).jpegData(compressionQuality: jpegQuality) else {
            throw ProcessingError.invalidImageData
        }
        return jpegData
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
