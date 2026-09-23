import Foundation
import Observation
import UIKit
import UniformTypeIdentifiers

/// Coordinates the Share Extension's one screen: loading the shared image
/// asynchronously, an optional ≤60-character caption, and saving into the
/// App Group share inbox. Never opens Core Data, CloudKit, or
/// `NSPersistentCloudKitContainer` — the only persistence this ViewModel
/// touches is `ShareInboxStoring`.
@MainActor
@Observable
final class ShareComposeViewModel {
    enum LoadState: Equatable {
        case loading
        case ready
        case error(String)
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case success
        case error(String)
    }

    let characterLimit = PendingShareLimits.maxCaptionLength

    private(set) var loadState: LoadState = .loading
    private(set) var saveState: SaveState = .idle
    private(set) var previewImage: UIImage?
    private(set) var rawImageData: Data?

    var captionText: String = "" {
        didSet {
            if captionText.count > characterLimit {
                captionText = String(captionText.prefix(characterLimit))
            }
        }
    }

    var characterCountLabel: String { "\(captionText.count)/\(characterLimit)" }
    var isCaptionValid: Bool { captionText.count <= characterLimit }
    var canSave: Bool { rawImageData != nil && saveState != .saving }

    private let shareInboxStore: ShareInboxStoring
    private let imageProcessor: ShareImageProcessor
    private let now: () -> Date

    init(
        shareInboxStore: ShareInboxStoring = AppGroupShareInboxStore(),
        imageProcessor: ShareImageProcessor = ShareImageProcessor(),
        now: @escaping () -> Date = Date.init
    ) {
        self.shareInboxStore = shareInboxStore
        self.imageProcessor = imageProcessor
        self.now = now
    }

    /// Loads the shared image from the extension's `NSItemProvider`. Never
    /// crashes for a missing provider, an unsupported type, or a decoding
    /// failure — each maps to a visible error state instead.
    func loadImage(from itemProvider: NSItemProvider?) async {
        let validProvider: NSItemProvider
        switch ShareAttachmentValidation.validateImageProvider(itemProvider) {
        case .failure(.missingAttachment):
            loadState = .error("No photo was found in this share.")
            return
        case .failure(.unsupportedType):
            loadState = .error("This item isn't a supported photo.")
            return
        case .success(let provider):
            validProvider = provider
        }

        do {
            let data = try await Self.loadImageData(from: validProvider)
            guard let uiImage = UIImage(data: data) else {
                loadState = .error("We couldn't read that photo. Please try another one.")
                return
            }
            rawImageData = data
            previewImage = uiImage
            loadState = .ready
        } catch {
            loadState = .error("We couldn't load that photo. Please try another one.")
        }
    }

    private static func loadImageData(from itemProvider: NSItemProvider) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: ShareComposeError.missingImageData)
                }
            }
        }
    }

    /// Processes and saves the image into the share inbox. Returns whether
    /// the save succeeded, so the caller can decide when to complete the
    /// extension request — it never completes on its own.
    @discardableResult
    func save() async -> Bool {
        guard let rawImageData else {
            saveState = .error("Please choose a photo first.")
            return false
        }
        let caption: String?
        switch ShareCaptionValidation.validate(captionText) {
        case .failure(.tooLong):
            saveState = .error("Captions must be 60 characters or fewer.")
            return false
        case .success(let validated):
            caption = validated
        }

        saveState = .saving
        do {
            let processedImageData = try imageProcessor.process(rawImageData)
            try shareInboxStore.saveShare(
                id: UUID(),
                imageData: processedImageData,
                caption: caption,
                createdAt: now(),
                source: PendingShareSource.photosShareExtension
            )
            saveState = .success
            // Release the full-resolution copies promptly rather than
            // holding them until the extension process itself terminates.
            self.rawImageData = nil
            self.previewImage = nil
            return true
        } catch {
            saveState = .error("We couldn't save this photo. Please try again.")
            return false
        }
    }
}

enum ShareComposeError: Error, Sendable {
    case missingImageData
}
