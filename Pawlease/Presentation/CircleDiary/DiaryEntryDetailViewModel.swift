import Foundation
import Observation

/// Coordinates the Diary Entry Detail workflow: loading an entry with its
/// comments and reactions, managing the comment composer, reacting with a
/// free-keyboard emoji, and deleting the entry (author only). Holds no
/// business rules itself — validation and authorization both live in Use
/// Cases / semantic value types.
@MainActor
@Observable
final class DiaryEntryDetailViewModel {
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
    private(set) var viewState: DiaryEntryDetailViewState?
    private(set) var commentSubmissionState: CommentSubmissionState = .idle
    private(set) var actionErrorMessage: String?
    private(set) var didDeleteEntry = false

    var commentText: String = "" {
        didSet {
            if commentText.count > characterLimit {
                commentText = String(commentText.prefix(characterLimit))
            }
        }
    }

    var commentCharacterCountLabel: String { "\(commentText.count)/\(characterLimit)" }

    var isCommentValid: Bool {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && commentText.count <= characterLimit
    }

    var canSubmitComment: Bool {
        isCommentValid && commentSubmissionState != .sending
    }

    var isSubmittingComment: Bool { commentSubmissionState == .sending }

    var commentErrorMessage: String? {
        if case .error(let message) = commentSubmissionState { return message }
        return nil
    }

    let privacyMonitor: DiaryPrivacyMonitor

    private let entryID: UUID
    private let currentMember: CircleMember
    private let loadDiaryDetailUseCase: LoadDiaryDetailUseCase
    private let addDiaryCommentUseCase: AddDiaryCommentUseCase
    private let deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase
    private let reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase
    private let reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase
    private let clock: ClockProviding

    init(
        entryID: UUID,
        currentMember: CircleMember,
        loadDiaryDetailUseCase: LoadDiaryDetailUseCase,
        addDiaryCommentUseCase: AddDiaryCommentUseCase,
        deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase,
        reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase,
        reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase,
        screenCaptureStateProviding: ScreenCaptureStateProviding,
        clock: ClockProviding
    ) {
        self.entryID = entryID
        self.currentMember = currentMember
        self.loadDiaryDetailUseCase = loadDiaryDetailUseCase
        self.addDiaryCommentUseCase = addDiaryCommentUseCase
        self.deleteDiaryEntryUseCase = deleteDiaryEntryUseCase
        self.reactToDiaryEntryUseCase = reactToDiaryEntryUseCase
        self.reactToDiaryCommentUseCase = reactToDiaryCommentUseCase
        self.clock = clock
        self.privacyMonitor = DiaryPrivacyMonitor(screenCaptureStateProviding: screenCaptureStateProviding)
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
            _ = try await addDiaryCommentUseCase.execute(entryID: entryID, author: currentMember, bodyText: commentText)
            commentText = ""
            commentSubmissionState = .idle
            await reload()
        } catch let error as DomainValidationError {
            commentSubmissionState = .error(Self.message(for: error))
        } catch {
            commentSubmissionState = .error("We couldn't post your comment. Please try again.")
        }
    }

    func deleteEntry() async {
        do {
            try await deleteDiaryEntryUseCase.execute(entryID: entryID, requestingProfileID: currentMember.profileID)
            didDeleteEntry = true
        } catch {
            actionErrorMessage = "We couldn't delete this entry. Please try again."
        }
    }

    /// `rawEmoji` comes straight from a plain system-keyboard text field —
    /// validated here (via `DiaryReactionEmoji`) before ever reaching the
    /// Use Case, exactly like every other Domain value type in this app.
    func reactToEntry(withRawEmoji rawEmoji: String) async {
        do {
            let emoji = try DiaryReactionEmoji(rawEmoji)
            try await reactToDiaryEntryUseCase.execute(entryID: entryID, memberProfileID: currentMember.profileID, emoji: emoji)
            actionErrorMessage = nil
            await reload()
        } catch let error as DomainValidationError {
            actionErrorMessage = Self.message(for: error)
        } catch {
            actionErrorMessage = "We couldn't save your reaction. Please try again."
        }
    }

    func reactToComment(commentID: UUID, withRawEmoji rawEmoji: String) async {
        do {
            let emoji = try DiaryReactionEmoji(rawEmoji)
            try await reactToDiaryCommentUseCase.execute(commentID: commentID, memberProfileID: currentMember.profileID, emoji: emoji)
            actionErrorMessage = nil
            await reload()
        } catch let error as DomainValidationError {
            actionErrorMessage = Self.message(for: error)
        } catch {
            actionErrorMessage = "We couldn't save your reaction. Please try again."
        }
    }

    private func reload() async {
        do {
            let result = try await loadDiaryDetailUseCase.execute(entryID: entryID)
            viewState = DiaryEntryDetailViewState(result: result, currentMemberProfileID: currentMember.profileID, now: clock.now)
            loadState = .loaded
        } catch {
            loadState = .error("This entry is no longer available.")
        }
    }

    private static func message(for error: DomainValidationError) -> String {
        switch error {
        case .invalidDiaryReactionEmoji: return "Please enter a single emoji."
        case .diaryBodyEmpty: return "Please write something before sending."
        case .diaryBodyTooLong: return "Diary entries must be 500 characters or fewer."
        case .commentTooLong: return "Comments must be 60 characters or fewer."
        case .commentEmpty: return "Please write something before sending."
        case .captionTooLong, .captionEmpty, .emptyPhotoData, .invalidReactionEmoji:
            return "Something went wrong. Please try again."
        }
    }
}
