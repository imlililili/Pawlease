import Foundation
import Observation

/// Coordinates the Post Detail workflow: loading a moment with its comments
/// and reactions, managing the comment composer's text and submission state,
/// and triggering reloads after a comment or reaction mutation succeeds.
/// Holds no business rules itself — reaction replacement and comment
/// authorization both live in Use Cases.
@MainActor
@Observable
final class PostDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    enum CommentSubmissionState: Equatable {
        case idle
        case sending
        case error(String)
    }

    let characterLimit = CommentBody.maxLength

    private(set) var loadState: LoadState = .idle
    private(set) var viewState: PostDetailViewState?
    private(set) var commentSubmissionState: CommentSubmissionState = .idle
    private(set) var actionErrorMessage: String?

    var commentText: String = "" {
        didSet {
            if commentText.count > characterLimit {
                commentText = String(commentText.prefix(characterLimit))
            }
        }
    }

    var commentCharacterCountLabel: String {
        "\(commentText.count)/\(characterLimit)"
    }

    var isCommentValid: Bool {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && commentText.count <= characterLimit
    }

    var canSubmitComment: Bool {
        isCommentValid && commentSubmissionState != .sending
    }

    var isSubmittingComment: Bool {
        commentSubmissionState == .sending
    }

    var commentErrorMessage: String? {
        if case .error(let message) = commentSubmissionState { return message }
        return nil
    }

    private let momentID: UUID
    private let currentMember: CircleMember
    private let loadMomentDetailUseCase: LoadMomentDetailUseCase
    private let addCommentUseCase: AddCommentUseCase
    private let removeCommentUseCase: RemoveCommentUseCase
    private let reactToMomentUseCase: ReactToMomentUseCase
    private let reactToCommentUseCase: ReactToCommentUseCase

    init(
        momentID: UUID,
        currentMember: CircleMember,
        loadMomentDetailUseCase: LoadMomentDetailUseCase,
        addCommentUseCase: AddCommentUseCase,
        removeCommentUseCase: RemoveCommentUseCase,
        reactToMomentUseCase: ReactToMomentUseCase,
        reactToCommentUseCase: ReactToCommentUseCase
    ) {
        self.momentID = momentID
        self.currentMember = currentMember
        self.loadMomentDetailUseCase = loadMomentDetailUseCase
        self.addCommentUseCase = addCommentUseCase
        self.removeCommentUseCase = removeCommentUseCase
        self.reactToMomentUseCase = reactToMomentUseCase
        self.reactToCommentUseCase = reactToCommentUseCase
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        loadState = .loading
        await reload()
    }

    func refresh() async {
        loadState = .loading
        await reload()
    }

    func submitComment() async {
        guard canSubmitComment else { return }
        commentSubmissionState = .sending
        do {
            _ = try await addCommentUseCase.execute(momentID: momentID, author: currentMember, bodyText: commentText)
            commentText = ""
            commentSubmissionState = .idle
            await reload()
        } catch let error as DomainValidationError {
            commentSubmissionState = .error(Self.message(for: error))
        } catch {
            commentSubmissionState = .error("We couldn't post your comment. Please try again.")
        }
    }

    func removeComment(commentID: UUID) async {
        do {
            try await removeCommentUseCase.execute(commentID: commentID, requestingMemberID: currentMember.profileID)
            actionErrorMessage = nil
            await reload()
        } catch {
            actionErrorMessage = "We couldn't remove that comment. Please try again."
        }
    }

    func reactToMoment(with emoji: ReactionEmoji) async {
        do {
            try await reactToMomentUseCase.execute(
                momentID: momentID,
                memberProfileID: currentMember.profileID,
                emoji: emoji
            )
            actionErrorMessage = nil
            await reload()
        } catch {
            actionErrorMessage = "We couldn't save your reaction. Please try again."
        }
    }

    func reactToComment(commentID: UUID, with emoji: ReactionEmoji) async {
        do {
            try await reactToCommentUseCase.execute(
                commentID: commentID,
                memberProfileID: currentMember.profileID,
                emoji: emoji
            )
            actionErrorMessage = nil
            await reload()
        } catch {
            actionErrorMessage = "We couldn't save your reaction. Please try again."
        }
    }

    private func reload() async {
        do {
            let result = try await loadMomentDetailUseCase.execute(momentID: momentID)
            viewState = PostDetailViewState(result: result, currentMemberProfileID: currentMember.profileID)
            loadState = .loaded
        } catch {
            loadState = .error(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        if let domainError = error as? DomainError {
            switch domainError {
            case .momentNotFound: return "This moment is no longer available."
            case .commentNotFound: return "That comment is no longer available."
            case .notCommentAuthor: return "You can only remove your own comments."
            case .circleNotFound, .memberNotFound, .petNotFound, .feedLocked, .pendingDraftCorrupted, .membershipFull:
                return "Something went wrong. Please try again."
            }
        }
        return "Something went wrong. Please try again."
    }

    private static func message(for error: DomainValidationError) -> String {
        switch error {
        case .commentTooLong: return "Comments must be 60 characters or fewer."
        case .commentEmpty: return "Please write something before sending."
        case .captionTooLong, .captionEmpty, .emptyPhotoData, .invalidReactionEmoji:
            return "Something went wrong. Please try again."
        }
    }
}
