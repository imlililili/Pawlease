import Testing
import UIKit
@testable import Pawlease

@MainActor
struct PhotoProcessingServiceTests {
    private let service = PhotoProcessingService()

    @Test
    func wideCameraPhotoIsPersistedAsSquareMainImageAndThumbnail() throws {
        let sourceData = try #require(makeImage(size: CGSize(width: 1_600, height: 900)).jpegData(compressionQuality: 1))

        let photo = try service.process(sourceData)
        let mainImage = try #require(UIImage(data: photo.imageData))
        let thumbnail = try #require(UIImage(data: photo.thumbnailData))

        #expect(mainImage.size.width == mainImage.size.height)
        #expect(thumbnail.size.width == thumbnail.size.height)
        #expect(mainImage.size.width <= 1_200)
        #expect(thumbnail.size.width <= 300)
    }

    @Test
    func repositionedLibraryPhotoProducesARealSquareImage() throws {
        let sourceImage = makeImage(size: CGSize(width: 800, height: 400))

        let croppedData = try #require(
            service.croppedData(
                from: sourceImage,
                viewportSide: 320,
                zoom: 1.5,
                offset: CGSize(width: 100, height: 0)
            )
        )
        let croppedImage = try #require(UIImage(data: croppedData))

        #expect(croppedImage.size.width == croppedImage.size.height)
    }

    private func makeImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
