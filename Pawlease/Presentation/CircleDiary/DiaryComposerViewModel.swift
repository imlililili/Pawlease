import Foundation
import Observation

/// Coordinates the Threads-style Diary composer: multiline text entry, a
/// visibility-duration selector, and publishing via
/// `PublishDiaryEntryUseCase`. No photo, no attachment, no mood — Diary
/// entries are text-only by design.
@MainActor
@Observable
final class DiaryComposerViewModel {
    enum PublishState: Equatable {
        case idle
        case publishing
        case error(String)
    }

    let characterLimit = DiaryEntryBody.maxLength

    var bodyText: String = "" {
        didSet {
            if bodyText.count > characterLimit {
                bodyText = String(bodyText.prefix(characterLimit))
            }
        }
    }
    var visibilityDuration: DiaryVisibilityDuration = .oneDay

    private(set) var publishState: PublishState = .idle
    private(set) var didPublish = false

    var characterCountLabel: String { "\(bodyText.count)/\(characterLimit)" }

    var isBodyValid: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && bodyText.count <= characterLimit
    }

    var canPublish: Bool {
        isBodyValid && publishState != .publishing
    }

    /// Whether the composer has unsaved text worth warning about before a
    /// dismissal.
    var hasUnsavedContent: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Explains the currently-selected visibility option — pure formatting
    /// of `DiaryVisibilityDuration`, never a business rule itself.
    var visibilityExplanation: String {
        switch visibilityDuration {
        case .oneDay: "Visible for 24 hours, then moves to My Archive. Expired entries keep their comments and reactions."
        case .threeDays: "Visible for 3 days, then moves to My Archive. Expired entries keep their comments and reactions."
        case .sevenDays: "Visible for 7 days, then moves to My Archive. Expired entries keep their comments and reactions."
        case .permanent: "Stays in the shared Circle Diary feed until you delete it."
        }
    }

    let author: CircleMember
    /// For the "Posting to <circleName>" caption — presentation-only.
    let circleName: String
    private let circleID: UUID
    private let publishDiaryEntryUseCase: PublishDiaryEntryUseCase

    init(circleID: UUID, circleName: String, author: CircleMember, publishDiaryEntryUseCase: PublishDiaryEntryUseCase) {
        self.circleID = circleID
        self.circleName = circleName
        self.author = author
        self.publishDiaryEntryUseCase = publishDiaryEntryUseCase
    }

    func publish() async {
        guard canPublish else { return }
        publishState = .publishing
        do {
            _ = try await publishDiaryEntryUseCase.execute(
                circleID: circleID,
                author: author,
                bodyText: bodyText,
                visibilityDuration: visibilityDuration
            )
            didPublish = true
            publishState = .idle
        } catch let error as DomainValidationError {
            publishState = .error(Self.message(for: error))
        } catch {
            publishState = .error("We couldn't publish this entry. Please try again.")
        }
    }

    private static func message(for error: DomainValidationError) -> String {
        switch error {
        case .diaryBodyEmpty: return "Please write something before posting."
        case .diaryBodyTooLong: return "Diary entries must be 500 characters or fewer."
        case .captionTooLong, .captionEmpty, .emptyPhotoData, .commentTooLong, .commentEmpty,
             .invalidReactionEmoji, .invalidDiaryReactionEmoji:
            return "Something went wrong. Please try again."
        }
    }
}
