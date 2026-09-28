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

        let normalized = image.normalizedOrientation().centerCroppedSquare()

        guard
            let mainData = normalized.resized(maxDimension: maxImageDimension).jpegData(compressionQuality: jpegQuality),
            let thumbnailData = normalized.resized(maxDimension: maxThumbnailDimension).jpegData(compressionQuality: jpegQuality)
        else {
            throw ProcessingError.invalidImageData
        }

        return try MomentPhoto(imageData: mainData, thumbnailData: thumbnailData)
    }

    func normalizedImage(from data: Data) -> UIImage? {
        UIImage(data: data)?.normalizedOrientation()
    }

    func centerCroppedData(from data: Data) -> Data? {
        guard let image = normalizedImage(from: data) else { return nil }
        return image.centerCroppedSquare().jpegData(compressionQuality: 0.95)
    }

    func croppedData(
        from image: UIImage,
        viewportSide: CGFloat,
        zoom: CGFloat,
        offset: CGSize
    ) -> Data? {
        let normalized = image.normalizedOrientation()
        guard viewportSide > 0, normalized.size.width > 0, normalized.size.height > 0 else { return nil }

        let clampedZoom = max(zoom, 1)
        let displayScale = max(
            viewportSide / normalized.size.width,
            viewportSide / normalized.size.height
        ) * clampedZoom
        let cropSide = viewportSide / displayScale
        let center = CGPoint(
            x: normalized.size.width / 2 - offset.width / displayScale,
            y: normalized.size.height / 2 - offset.height / displayScale
        )
        let maximumOriginX = max(normalized.size.width - cropSide, 0)
        let maximumOriginY = max(normalized.size.height - cropSide, 0)
        let cropRect = CGRect(
            x: min(max(center.x - cropSide / 2, 0), maximumOriginX),
            y: min(max(center.y - cropSide / 2, 0), maximumOriginY),
            width: min(cropSide, normalized.size.width),
            height: min(cropSide, normalized.size.height)
        )

        guard let cropped = normalized.cropped(to: cropRect) else { return nil }
        return cropped.jpegData(compressionQuality: 0.95)
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resized(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension, largestSide > 0 else { return self }
        let scaleFactor = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func centerCroppedSquare() -> UIImage {
        let side = min(size.width, size.height)
        let rect = CGRect(
            x: (size.width - side) / 2,
            y: (size.height - side) / 2,
            width: side,
            height: side
        )
        return cropped(to: rect) ?? self
    }

    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage else { return nil }
        let xScale = CGFloat(cgImage.width) / size.width
        let yScale = CGFloat(cgImage.height) / size.height
        let requestedWidth = max((rect.width * xScale).rounded(), 1)
        let requestedHeight = max((rect.height * yScale).rounded(), 1)
        let isSquareCrop = abs(rect.width - rect.height) < 0.5
        let pixelWidth = isSquareCrop ? min(requestedWidth, requestedHeight) : requestedWidth
        let pixelHeight = isSquareCrop ? pixelWidth : requestedHeight
        let pixelRect = CGRect(
            x: min(max((rect.origin.x * xScale).rounded(), 0), CGFloat(cgImage.width) - pixelWidth),
            y: min(max((rect.origin.y * yScale).rounded(), 0), CGFloat(cgImage.height) - pixelHeight),
            width: pixelWidth,
            height: pixelHeight
        )

        guard let croppedCGImage = cgImage.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: .up)
    }
}
