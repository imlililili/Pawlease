import Testing
import Foundation
@testable import Pawlease

/// Integration tests against the real filesystem, using a temporary
/// directory via `AppGroupShareInboxStore(rootDirectory:)` — never the real
/// `group.com.lili.Pawlease` App Group container. Kept separate from the
/// mock-based unit tests above.
struct AppGroupShareInboxStoreFilesystemTests {
    private func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("ShareInboxTest-\(UUID().uuidString)", isDirectory: true)
    }

    @Test
    func savedShareRoundTripsThroughTheRealFilesystem() throws {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let store = AppGroupShareInboxStore(rootDirectory: tempDir)

        let id = UUID()
        let imageData = Data([0xFF, 0xD8, 0xFF])
        let manifest = try store.saveShare(id: id, imageData: imageData, caption: "Hello", createdAt: Date(), source: PendingShareSource.photosShareExtension)

        let manifests = store.loadPendingManifests()
        #expect(manifests.count == 1)
        #expect(manifests.first?.id == id)

        let loadedImage = store.loadImageData(filename: manifest.imageFilename)
        #expect(loadedImage == imageData)

        store.removeManifest(id: id)
        #expect(store.loadPendingManifests().isEmpty)
        // Removing the manifest must never delete the image it pointed to.
        #expect(store.loadImageData(filename: manifest.imageFilename) == imageData)

        store.removeImage(filename: manifest.imageFilename)
        #expect(store.loadImageData(filename: manifest.imageFilename) == nil)
    }

    @Test
    func corruptManifestFilesAreDiscardedDuringListing() throws {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let manifestsDir = tempDir.appendingPathComponent("ShareInbox/manifests", isDirectory: true)
        try FileManager.default.createDirectory(at: manifestsDir, withIntermediateDirectories: true)
        let corruptURL = manifestsDir.appendingPathComponent("corrupt.json")
        try Data("not valid json".utf8).write(to: corruptURL)

        let store = AppGroupShareInboxStore(rootDirectory: tempDir)
        let manifests = store.loadPendingManifests()

        #expect(manifests.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: corruptURL.path))
    }

    @Test
    func multiplePendingSharesAreOrderedDeterministicallyByCreationDate() throws {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let store = AppGroupShareInboxStore(rootDirectory: tempDir)

        let later = try store.saveShare(id: UUID(), imageData: Data([0x01]), caption: nil, createdAt: TestFactories.date(year: 2026, month: 9, day: 23, hour: 10), source: PendingShareSource.photosShareExtension)
        let earlier = try store.saveShare(id: UUID(), imageData: Data([0x02]), caption: nil, createdAt: TestFactories.date(year: 2026, month: 9, day: 23, hour: 8), source: PendingShareSource.photosShareExtension)

        let manifests = store.loadPendingManifests()
        #expect(manifests.map(\.id) == [earlier.id, later.id])
    }

    @Test
    func twoSharesSavedInARowDoNotOverwriteEachOthersFiles() throws {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let store = AppGroupShareInboxStore(rootDirectory: tempDir)

        let first = try store.saveShare(id: UUID(), imageData: Data([0xAA]), caption: nil, createdAt: Date(), source: PendingShareSource.photosShareExtension)
        let second = try store.saveShare(id: UUID(), imageData: Data([0xBB]), caption: nil, createdAt: Date(), source: PendingShareSource.photosShareExtension)

        #expect(first.imageFilename != second.imageFilename)
        #expect(store.loadImageData(filename: first.imageFilename) == Data([0xAA]))
        #expect(store.loadImageData(filename: second.imageFilename) == Data([0xBB]))
    }
}
