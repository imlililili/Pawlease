import Foundation

/// Implements `ShareInboxStoring` over the App Group container's
/// filesystem: `ShareInbox/manifests/<id>.json` + `ShareInbox/images/<id>.jpg`.
/// The only place either the Share Extension or the main app touches
/// `FileManager` for this data.
final class AppGroupShareInboxStore: ShareInboxStoring, @unchecked Sendable {
    static let appGroupIdentifier = "group.com.lili.Pawlease"

    private let fileManager: FileManager
    private let rootDirectory: URL?

    /// `appGroupIdentifier` is overridable so tests can point this at a
    /// resolvable App Group suite; `rootDirectory` lets tests bypass App
    /// Group resolution entirely and point straight at a temporary
    /// directory — no entitlement, Core Data, or CloudKit involved either
    /// way.
    init(appGroupIdentifier: String = AppGroupShareInboxStore.appGroupIdentifier, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.rootDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.rootDirectory = rootDirectory
    }

    private var manifestsDirectory: URL? {
        rootDirectory?.appendingPathComponent("ShareInbox/manifests", isDirectory: true)
    }

    private var imagesDirectory: URL? {
        rootDirectory?.appendingPathComponent("ShareInbox/images", isDirectory: true)
    }

    @discardableResult
    func saveShare(
        id: UUID,
        imageData: Data,
        caption: String?,
        createdAt: Date,
        source: String
    ) throws -> PendingShareManifest {
        guard let manifestsDirectory, let imagesDirectory else {
            throw ShareInboxError.appGroupUnavailable
        }
        try fileManager.createDirectory(at: manifestsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let imageFilename = "\(id.uuidString).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(imageFilename)
        try imageData.write(to: imageURL, options: .atomic)

        let manifest = PendingShareManifest(id: id, caption: caption, imageFilename: imageFilename, createdAt: createdAt, source: source)
        let manifestURL = manifestsDirectory.appendingPathComponent("\(id.uuidString).json")

        do {
            let manifestData = try JSONEncoder().encode(manifest)
            try manifestData.write(to: manifestURL, options: .atomic)
        } catch {
            // Roll back the now-orphaned image so a partial share never
            // lingers without a manifest to describe it.
            try? fileManager.removeItem(at: imageURL)
            throw error
        }

        return manifest
    }

    func loadPendingManifests() -> [PendingShareManifest] {
        guard let manifestsDirectory,
              let urls = try? fileManager.contentsOfDirectory(at: manifestsDirectory, includingPropertiesForKeys: nil)
        else {
            return []
        }

        let decoder = JSONDecoder()
        var manifests: [PendingShareManifest] = []
        for url in urls where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let manifest = try? decoder.decode(PendingShareManifest.self, from: data)
            else {
                // Corrupt manifest: safe to discard — it carries no
                // recoverable user data by itself, unlike the image file it
                // may or may not point to.
                try? fileManager.removeItem(at: url)
                continue
            }
            manifests.append(manifest)
        }

        return manifests.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    func loadImageData(filename: String) -> Data? {
        guard let imagesDirectory, let url = Self.safeFileURL(forFilename: filename, in: imagesDirectory) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    func removeManifest(id: UUID) {
        guard let manifestsDirectory else { return }
        let url = manifestsDirectory.appendingPathComponent("\(id.uuidString).json")
        try? fileManager.removeItem(at: url)
    }

    func removeImage(filename: String) {
        guard let imagesDirectory, let url = Self.safeFileURL(forFilename: filename, in: imagesDirectory) else { return }
        try? fileManager.removeItem(at: url)
    }

    /// Rejects anything that isn't a bare filename — no path separators, no
    /// `.`/`..` — and, as defense in depth, also rejects a resolved path
    /// that ends up outside `directory` after standardization.
    static func safeFileURL(forFilename filename: String, in directory: URL) -> URL? {
        guard !filename.isEmpty,
              filename != ".",
              filename != "..",
              !filename.contains("/"),
              !filename.contains("\\")
        else {
            return nil
        }

        let standardizedDirectory = directory.standardizedFileURL
        let candidate = standardizedDirectory.appendingPathComponent(filename).standardizedFileURL
        guard candidate.path.hasPrefix(standardizedDirectory.path + "/") else {
            return nil
        }
        return candidate
    }
}
