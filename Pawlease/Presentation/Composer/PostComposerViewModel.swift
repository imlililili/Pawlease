import Foundation
import Observation
import PhotosUI
import SwiftUI

/// Coordinates the Post Composer workflow: photo selection and preview,
/// caption entry with a live character count, optional mood, and
/// publishing via `PublishDailyMomentUseCase`.
@MainActor
@Observable
final class PostComposerViewModel {
    enum PublishState: Equatable {
        case idle
        case publishing
        case error(String)
    }

    let moodOptions = ["😀", "😐", "😴", "🥳", "😭", "😎"]
    let characterLimit = MomentCaption.maxLength

    var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadSelectedPhoto() } }
    }
    private(set) var previewImage: Image?
    private(set) var rawImageData: Data?

    var captionText: String = "" {
        didSet {
            if captionText.count > characterLimit {
                captionText = String(captionText.prefix(characterLimit))
            }
        }
    }
    var selectedMood: String?

    private(set) var publishState: PublishState = .idle
    private(set) var didPublish = false

    var viewState: PostComposerViewState {
        PostComposerViewState(captionText: captionText, limit: characterLimit)
    }

    var canPublish: Bool {
        rawImageData != nil && viewState.isCaptionValid && publishState != .publishing
    }

    private let circle: FriendCircle
    private let member: CircleMember
    private let publishDailyMomentUseCase: PublishDailyMomentUseCase
    private let photoProcessingService: PhotoProcessingService

    init(
        circle: FriendCircle,
        member: CircleMember,
        publishDailyMomentUseCase: PublishDailyMomentUseCase,
        photoProcessingService: PhotoProcessingService
    ) {
        self.circle = circle
        self.member = member
        self.publishDailyMomentUseCase = publishDailyMomentUseCase
        self.photoProcessingService = photoProcessingService
    }

    private func loadSelectedPhoto() async {
        guard let selectedItem else { return }
        do {
            guard let data = try await selectedItem.loadTransferable(type: Data.self) else { return }
            rawImageData = data
            if let uiImage = UIImage(data: data) {
                previewImage = Image(uiImage: uiImage)
            }
        } catch {
            publishState = .error("Couldn't load that photo. Please try another one.")
        }
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
                captionText: captionText,
                moodEmoji: selectedMood
            )
            didPublish = true
            publishState = .idle
        } catch let error as DomainValidationError {
            publishState = .error(Self.message(for: error))
        } catch {
            publishState = .error("We couldn't publish this moment. Your photo is safe — please try again.")
        }
    }

    private static func message(for error: DomainValidationError) -> String {
        switch error {
        case .captionTooLong: return "Captions must be 60 characters or fewer."
        case .captionEmpty: return "Please add a short caption."
        case .emptyPhotoData: return "That photo couldn't be processed. Please try another one."
        case .commentTooLong, .commentEmpty, .invalidReactionEmoji:
            return "Something went wrong. Please try again."
        }
    }
}
