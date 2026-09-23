import Foundation
@testable import Pawlease

final class MockShareInboxStore: ShareInboxStoring, @unchecked Sendable {
    var saveShareError: Error?
    private(set) var savedShares: [(id: UUID, imageData: Data, caption: String?, createdAt: Date, source: String)] = []
    private(set) var saveShareCallCount = 0

    var stubbedPendingManifests: [PendingShareManifest] = []

    var imageDataByFilename: [String: Data] = [:]
    private(set) var loadImageDataCalls: [String] = []

    private(set) var removedManifestIDs: [UUID] = []
    private(set) var removedImageFilenames: [String] = []

    @discardableResult
    func saveShare(id: UUID, imageData: Data, caption: String?, createdAt: Date, source: String) throws -> PendingShareManifest {
        saveShareCallCount += 1
        if let saveShareError { throw saveShareError }
        savedShares.append((id, imageData, caption, createdAt, source))
        let manifest = PendingShareManifest(id: id, caption: caption, imageFilename: "\(id.uuidString).jpg", createdAt: createdAt, source: source)
        stubbedPendingManifests.append(manifest)
        return manifest
    }

    func loadPendingManifests() -> [PendingShareManifest] {
        stubbedPendingManifests
    }

    func loadImageData(filename: String) -> Data? {
        loadImageDataCalls.append(filename)
        return imageDataByFilename[filename]
    }

    func removeManifest(id: UUID) {
        removedManifestIDs.append(id)
        stubbedPendingManifests.removeAll { $0.id == id }
    }

    func removeImage(filename: String) {
        removedImageFilenames.append(filename)
    }
}
