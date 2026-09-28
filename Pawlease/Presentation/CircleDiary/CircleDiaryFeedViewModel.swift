import Foundation
import Observation

/// Coordinates the Circle Diary feed: loading active entries, presenting
/// the composer, and building the Detail/Archive screens. Holds no
/// business rules itself — everything is delegated to Use Cases.
@MainActor
@Observable
final class CircleDiaryFeedViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var feedItems: [LoadActiveDiaryFeedUseCase.FeedItem] = []
    var isComposerPresented = false
    var isArchivePresented = false

    let privacyMonitor: DiaryPrivacyMonitor

    var viewState: CircleDiaryFeedViewState {
        CircleDiaryFeedViewState(items: feedItems, now: clock.now)
    }

    let circleID: UUID
    let currentMember: CircleMember
    private let loadActiveDiaryFeedUseCase: LoadActiveDiaryFeedUseCase
    private let publishDiaryEntryUseCase: PublishDiaryEntryUseCase
    private let loadDiaryDetailUseCase: LoadDiaryDetailUseCase
    private let addDiaryCommentUseCase: AddDiaryCommentUseCase
    private let deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase
    private let reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase
    private let reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase
    private let loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase
    private let screenCaptureStateProviding: ScreenCaptureStateProviding
    private let clock: ClockProviding

    init(
        circleID: UUID,
        currentMember: CircleMember,
        loadActiveDiaryFeedUseCase: LoadActiveDiaryFeedUseCase,
        publishDiaryEntryUseCase: PublishDiaryEntryUseCase,
        loadDiaryDetailUseCase: LoadDiaryDetailUseCase,
        addDiaryCommentUseCase: AddDiaryCommentUseCase,
        deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase,
        reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase,
        reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase,
        loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase,
        screenCaptureStateProviding: ScreenCaptureStateProviding,
        clock: ClockProviding
    ) {
        self.circleID = circleID
        self.currentMember = currentMember
        self.loadActiveDiaryFeedUseCase = loadActiveDiaryFeedUseCase
        self.publishDiaryEntryUseCase = publishDiaryEntryUseCase
        self.loadDiaryDetailUseCase = loadDiaryDetailUseCase
        self.addDiaryCommentUseCase = addDiaryCommentUseCase
        self.deleteDiaryEntryUseCase = deleteDiaryEntryUseCase
        self.reactToDiaryEntryUseCase = reactToDiaryEntryUseCase
        self.reactToDiaryCommentUseCase = reactToDiaryCommentUseCase
        self.loadMyDiaryArchiveUseCase = loadMyDiaryArchiveUseCase
        self.screenCaptureStateProviding = screenCaptureStateProviding
        self.clock = clock
        self.privacyMonitor = DiaryPrivacyMonitor(screenCaptureStateProviding: screenCaptureStateProviding)
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await refresh()
    }

    func refresh() async {
        loadState = .loading
        do {
            feedItems = try await loadActiveDiaryFeedUseCase.execute(circleID: circleID)
            loadState = .loaded
        } catch {
            loadState = .error("We couldn't load the Circle Diary. Please try again.")
        }
    }

    func presentComposer() {
        isComposerPresented = true
    }

    func handleComposerDismissed(didPublish: Bool) async {
        isComposerPresented = false
        if didPublish {
            await refresh()
        }
    }

    func makeComposerViewModel() -> DiaryComposerViewModel {
        DiaryComposerViewModel(
            circleID: circleID,
            author: currentMember,
            publishDiaryEntryUseCase: publishDiaryEntryUseCase
        )
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

    func makeArchiveViewModel() -> DiaryArchiveViewModel {
        DiaryArchiveViewModel(
            circleID: circleID,
            currentMember: currentMember,
            loadMyDiaryArchiveUseCase: loadMyDiaryArchiveUseCase,
            deleteDiaryEntryUseCase: deleteDiaryEntryUseCase,
            loadDiaryDetailUseCase: loadDiaryDetailUseCase,
            addDiaryCommentUseCase: addDiaryCommentUseCase,
            reactToDiaryEntryUseCase: reactToDiaryEntryUseCase,
            reactToDiaryCommentUseCase: reactToDiaryCommentUseCase,
            screenCaptureStateProviding: screenCaptureStateProviding,
            clock: clock
        )
    }
}
