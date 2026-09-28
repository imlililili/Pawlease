import Foundation
import Observation

/// Coordinates "My Diary Archive": the current member's own expired timed
/// entries. Archived posts are read-only except that their author can still
/// delete them, so this reuses `DiaryEntryDetailViewModel` for that screen
/// rather than duplicating delete/reaction logic.
@MainActor
@Observable
final class DiaryArchiveViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var entries: [DiaryEntry] = []

    private let circleID: UUID
    private let currentMember: CircleMember
    private let loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase
    private let deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase
    private let loadDiaryDetailUseCase: LoadDiaryDetailUseCase
    private let addDiaryCommentUseCase: AddDiaryCommentUseCase
    private let reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase
    private let reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase
    private let screenCaptureStateProviding: ScreenCaptureStateProviding
    private let clock: ClockProviding

    init(
        circleID: UUID,
        currentMember: CircleMember,
        loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase,
        deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase,
        loadDiaryDetailUseCase: LoadDiaryDetailUseCase,
        addDiaryCommentUseCase: AddDiaryCommentUseCase,
        reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase,
        reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase,
        screenCaptureStateProviding: ScreenCaptureStateProviding,
        clock: ClockProviding
    ) {
        self.circleID = circleID
        self.currentMember = currentMember
        self.loadMyDiaryArchiveUseCase = loadMyDiaryArchiveUseCase
        self.deleteDiaryEntryUseCase = deleteDiaryEntryUseCase
        self.loadDiaryDetailUseCase = loadDiaryDetailUseCase
        self.addDiaryCommentUseCase = addDiaryCommentUseCase
        self.reactToDiaryEntryUseCase = reactToDiaryEntryUseCase
        self.reactToDiaryCommentUseCase = reactToDiaryCommentUseCase
        self.screenCaptureStateProviding = screenCaptureStateProviding
        self.clock = clock
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await refresh()
    }

    func refresh() async {
        loadState = .loading
        do {
            entries = try await loadMyDiaryArchiveUseCase.execute(circleID: circleID, memberProfileID: currentMember.profileID)
            loadState = .loaded
        } catch {
            loadState = .error("We couldn't load your Archive. Please try again.")
        }
    }

    func makeDetailViewModel(entryID: UUID) -> DiaryEntryDetailViewModel {
        DiaryEntryDetailViewModel(
            entryID: entryID,
            currentMember: currentMember,
            loadDiaryDetailUseCase: loadDiaryDetailUseCase,
            addDiaryCommentUseCase: addDiaryCommentUseCase,
            deleteDiaryEntryUseCase: deleteDiaryEntryUseCase,
            reactToDiaryEntryUseCase: reactToDiaryEntryUseCase,
            reactToDiaryCommentUseCase: reactToDiaryCommentUseCase,
            screenCaptureStateProviding: screenCaptureStateProviding,
            clock: clock
        )
    }
}
