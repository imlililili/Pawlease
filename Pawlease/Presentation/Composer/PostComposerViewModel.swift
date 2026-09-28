import Foundation
import Observation
import PhotosUI
import SwiftUI

/// Coordinates Moment composition from either the camera or PhotosPicker and
/// publishes through `PublishDailyMomentUseCase`.
@MainActor
@Observable
final class PostComposerViewModel {
    enum PublishState: Equatable {
        case idle
        case publishing
        case error(String)
    }

    let characterLimit = MomentCaption.maxLength

    var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadSelectedPhoto() } }
    }
    private(set) var previewImage: Image?
    private(set) var rawImageData: Data?
    private(set) var pendingCropImage: UIImage?

    var captionText: String = "" {
        didSet {
            if captionText.count > characterLimit {
                captionText = String(captionText.prefix(characterLimit))
            }
        }
    }
    private(set) var publishState: PublishState = .idle
    private(set) var didPublish = false

    var viewState: PostComposerViewState {
        PostComposerViewState(captionText: captionText, limit: characterLimit)
    }

    var canPublish: Bool {
        rawImageData != nil && viewState.isCaptionValid && publishState != .publishing
    }

    /// Set only when this composer was opened from a shared-photo banner
    /// (see `PetHomeViewModel.makeComposerViewModel(forPendingDraft:)`).
    /// `nil` for the normal "Take Today's Photo" flow.
    private let pendingDraftID: UUID?
    private let pendingDraftImageFilename: String?

    private let circle: FriendCircle
    private let member: CircleMember
    private let publishDailyMomentUseCase: PublishDailyMomentUseCase
    private let photoProcessingService: PhotoProcessingService
    private let consumePendingDraftUseCase: ConsumePendingDraftUseCase?

    init(
        circle: FriendCircle,
        member: CircleMember,
        publishDailyMomentUseCase: PublishDailyMomentUseCase,
        photoProcessingService: PhotoProcessingService,
        prefilledImageData: Data? = nil,
        prefilledCaption: String? = nil,
        pendingDraftID: UUID? = nil,
        pendingDraftImageFilename: String? = nil,
        consumePendingDraftUseCase: ConsumePendingDraftUseCase? = nil
    ) {
        self.circle = circle
        self.member = member
        self.publishDailyMomentUseCase = publishDailyMomentUseCase
        self.photoProcessingService = photoProcessingService
        self.pendingDraftID = pendingDraftID
        self.pendingDraftImageFilename = pendingDraftImageFilename
        self.consumePendingDraftUseCase = consumePendingDraftUseCase

        if let prefilledImageData {
            self.rawImageData = prefilledImageData
            if let uiImage = UIImage(data: prefilledImageData) {
                self.previewImage = Image(uiImage: uiImage)
            }
        }
        if let prefilledCaption {
            self.captionText = String(prefilledCaption.prefix(characterLimit))
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedItem else { return }
        do {
            guard let data = try await selectedItem.loadTransferable(type: Data.self) else { return }
            guard let image = photoProcessingService.normalizedImage(from: data) else {
                publishState = .error("That photo couldn't be loaded. Please try again.")
                return
            }
            pendingCropImage = image
        } catch {
            publishState = .error("Couldn't load that photo. Please try another one.")
        }
    }

    func setCapturedPhotoData(_ data: Data) {
        guard let croppedData = photoProcessingService.centerCroppedData(from: data) else {
            publishState = .error("That photo couldn't be loaded. Please try again.")
            return
        }
        setPhotoData(croppedData)
    }

    func useCroppedLibraryPhoto(_ data: Data) {
        pendingCropImage = nil
        selectedItem = nil
        setPhotoData(data)
    }

    func cancelLibraryPhotoCrop() {
        pendingCropImage = nil
        selectedItem = nil
    }

    private func setPhotoData(_ data: Data) {
        guard let uiImage = UIImage(data: data) else {
            publishState = .error("That photo couldn't be loaded. Please try again.")
            return
        }
        rawImageData = data
        previewImage = Image(uiImage: uiImage)
        publishState = .idle
    }

    func publish() async {
        guard let rawImageData else {
            publishState = .error("Please choose a photo first.")
            return
        }

        publishState = .publishing
        do {
            let photo = try photoProcessingService.process(rawImageData)
            _ = try await publishDailyMomentUseCase.execute(
                circle: circle,
                member: member,
                photo: photo,
                captionText: captionText
            )
            didPublish = true
            publishState = .idle

            if let pendingDraftID, let pendingDraftImageFilename {
                await consumePendingDraftUseCase?.execute(draftID: pendingDraftID, imageFilename: pendingDraftImageFilename)
            }
        } catch let error as DomainValidationError {
            publishState = .error(Self.message(for: error))
        } catch {
            publishState = .error("We couldn't publish this moment. Your photo is safe — please try again.")
        }
    }

    private static func message(for error: DomainValidationError) -> String {
        switch error {
        case .captionTooLong: return "Captions must be 60 characters or fewer."
        case .captionEmpty: return "Captions are optional."
        case .emptyPhotoData: return "That photo couldn't be processed. Please try another one."
        case .commentTooLong, .commentEmpty, .invalidReactionEmoji:
            return "Something went wrong. Please try again."
        }
    }
}
