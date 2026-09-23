import Testing
import Foundation
@testable import Pawlease

/// Tests the pure, static path-traversal guard — no filesystem I/O, no App
/// Group. Filesystem behavior itself is covered separately in
/// AppGroupShareInboxStoreFilesystemTests.
struct AppGroupShareInboxStoreSafetyTests {
    @Test
    func pathTraversalFilenamesAreRejected() {
        let directory = URL(fileURLWithPath: "/tmp/pawlease-share-inbox-safety-test", isDirectory: true)
        let traversalAttempts = ["../secret.txt", "a/../../etc/passwd", "/etc/passwd", "..", ".", "", "a/b.jpg", "a\\b.jpg"]

        for filename in traversalAttempts {
            #expect(AppGroupShareInboxStore.safeFileURL(forFilename: filename, in: directory) == nil, "Expected \(filename) to be rejected")
        }
    }

    @Test
    func aBareFilenameResolvesInsideTheGivenDirectory() {
        let directory = URL(fileURLWithPath: "/tmp/pawlease-share-inbox-safety-test", isDirectory: true)

        let resolved = AppGroupShareInboxStore.safeFileURL(forFilename: "abc123.jpg", in: directory)

        #expect(resolved != nil)
        #expect(resolved?.lastPathComponent == "abc123.jpg")
        #expect(resolved?.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL)
    }
}
