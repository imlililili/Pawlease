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
    let circleName: String
    /// For the feed's introductory "A private text feed for the people who
    /// share <petName>." description — presentation-only, never used for
    /// any business rule.
    let petName: String
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
    /// Memoized per entry by `makeDetailViewModel(entryID:)` — see its doc
    /// comment for why a fresh instance per call destabilizes the stack.
    private var detailViewModelsByEntryID: [UUID: DiaryEntryDetailViewModel] = [:]

    init(
        circleID: UUID,
        currentMember: CircleMember,
        circleName: String,
        petName: String,
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
        self.circleName = circleName
        self.petName = petName
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

    /// Deletes one of the current member's own entries directly from the
    /// feed row's overflow menu. Authorization is still enforced by
    /// `DeleteDiaryEntryUseCase`/the repository — this is only reachable
    /// from the UI for the author's own rows in the first place.
    func deleteEntry(entryID: UUID) async {
        do {
            try await deleteDiaryEntryUseCase.execute(entryID: entryID, requestingProfileID: currentMember.profileID)
            await refresh()
        } catch {
            loadState = .error("We couldn't delete that entry. Please try again.")
        }
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
            circleName: circleName,
            author: currentMember,
            publishDiaryEntryUseCase: publishDiaryEntryUseCase
        )
    }

    /// Returns the same memoized instance (keyed by `entryID`) on every call
    /// after the first. `.navigationDestination(for:)`'s closure is not
    /// guaranteed to run exactly once per push — any ancestor re-render that
    /// touches `@Observable` state read by `CircleDiaryFeedView.body` (e.g.
    /// `privacyMonitor` ticking) can make SwiftUI re-invoke it while the
    /// route is still active. A non-idempotent factory there produced two
    /// competing `DiaryEntryDetailView`/`DiaryEntryDetailViewModel`
    /// identities for one push — confirmed via direct instrumentation — and
    /// having two made the stack's own bookkeeping unstable, popping the
    /// user back out. Same fix, same reasoning as `diaryFeedViewModel` in
    /// `PetHomeViewModel`.
    func makeDetailViewModel(entryID: UUID) -> DiaryEntryDetailViewModel {
        if let existing = detailViewModelsByEntryID[entryID] { return existing }
        let viewModel = DiaryEntryDetailViewModel(
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
        detailViewModelsByEntryID[entryID] = viewModel
        return viewModel
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
