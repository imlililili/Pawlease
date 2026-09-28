import Foundation
import Observation

/// Coordinates the Pet Home workflow: loading the seeded Circle snapshot,
/// unlocking/loading today's feed, and presenting the Post Composer. Holds
/// no business rules itself — everything is delegated to Use Cases.
@MainActor
@Observable
final class PetHomeViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    /// State for the Debug-only "Simulate Friend Check-in" control. Whether
    /// the demo friend has *already* checked in today is deliberately not
    /// tracked here as separate mutable state — it's derived from
    /// `todayMoments` (see `hasDemoFriendCheckedInToday`), which `refresh()`
    /// already reloads from persisted posts, so it survives view reloads
    /// and app relaunches without needing its own persistence.
    enum DemoCheckInState: Equatable {
        case idle
        case checkingIn
        case error(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var snapshot: PetHomeSnapshot?
    private(set) var todayMoments: [DailyMoment] = []
    private(set) var feedError: String?
    private(set) var syncStatus: CircleSyncStatus = .localChangesSaved
    private(set) var pendingSharedDraft: PendingPostDraft?
    private(set) var demoCheckInState: DemoCheckInState = .idle
    var isComposerPresented = false
    var isJoinCirclePresented = false

    var viewState: PetHomeViewState? {
        snapshot.map(PetHomeViewState.init)
    }

    /// Whether the Debug-only demo friend has already posted for today's
    /// Circle day — derived from the same `todayMoments` the real feed
    /// shows, never a separately tracked flag.
    var hasDemoFriendCheckedInToday: Bool {
        todayMoments.contains { $0.authorProfileID == DemoSeed.avaProfileID }
    }

    /// The button is disabled until the current user has posted today —
    /// mirroring the same rule the Use Case itself enforces — and while a
    /// simulation is already in flight.
    var canSimulateFriendCheckIn: Bool {
        (snapshot?.hasCurrentMemberPosted ?? false) && demoCheckInState != .checkingIn
    }

    private let loadPetHomeUseCase: LoadPetHomeUseCase
    private let loadTodayMomentsUseCase: LoadTodayMomentsUseCase
    private let seedDemoCircleUseCase: SeedDemoCircleUseCase
    private let publishDailyMomentUseCase: PublishDailyMomentUseCase
    private let photoProcessingService: PhotoProcessingService
    private let loadMomentDetailUseCase: LoadMomentDetailUseCase
    private let addCommentUseCase: AddCommentUseCase
    private let removeCommentUseCase: RemoveCommentUseCase
    private let reactToMomentUseCase: ReactToMomentUseCase
    private let reactToCommentUseCase: ReactToCommentUseCase
    private let loadCircleMembersUseCase: LoadCircleMembersUseCase
    private let checkCloudAccountUseCase: CheckCloudAccountUseCase
    private let loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase
    private let prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase
    private let refreshSharedCircleUseCase: RefreshSharedCircleUseCase
    private let loadActiveCircleInviteCodeUseCase: LoadActiveCircleInviteCodeUseCase
    private let createCircleInviteCodeUseCase: CreateCircleInviteCodeUseCase
    private let revokeCircleInviteCodeUseCase: RevokeCircleInviteCodeUseCase
    private let resolveCircleInviteCodeUseCase: ResolveCircleInviteCodeUseCase
    private let shareURLOpener: ShareURLOpening
    private let remoteChangeSignal: RemoteChangeSignaling
    private let cloudSyncEventSignal: CloudSyncEventSignaling
    private let publishWidgetSnapshotUseCase: PublishWidgetSnapshotUseCase
    private let importPendingSharesUseCase: ImportPendingSharesUseCase
    private let loadPendingDraftsUseCase: LoadPendingDraftsUseCase
    private let loadPendingDraftImageUseCase: LoadPendingDraftImageUseCase
    private let consumePendingDraftUseCase: ConsumePendingDraftUseCase
    private let simulateFriendCheckInUseCase: SimulateFriendCheckInUseCase
    private let cleanUpLegacyDemoFriendUseCase: CleanUpLegacyDemoFriendUseCase
    private let publishDiaryEntryUseCase: PublishDiaryEntryUseCase
    private let loadActiveDiaryFeedUseCase: LoadActiveDiaryFeedUseCase
    private let loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase
    private let loadDiaryDetailUseCase: LoadDiaryDetailUseCase
    private let addDiaryCommentUseCase: AddDiaryCommentUseCase
    private let reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase
    private let reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase
    private let deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase
    private let screenCaptureStateProviding: ScreenCaptureStateProviding
    private let clock: ClockProviding
    /// Memoized by `makeCircleDiaryFeedViewModel()` so Pet Home's push to
    /// Circle Diary stays backed by one stable `CircleDiaryFeedViewModel`
    /// instance for the life of this screen, rather than a fresh one on
    /// every `PetHomeView.body` re-evaluation (remote-change pulses, cloud
    /// sync events, scene-phase changes). A closure-based `NavigationLink`
    /// constructs its destination eagerly on every such re-render; without
    /// this cache, that meant a brand-new `CircleDiaryFeedView` identity —
    /// and a freshly re-registered `.navigationDestination(for:
    /// DiaryEntryRoute.self)` — while the user was still pushed into it,
    /// which is what produced the "declared earlier on the stack" warning
    /// and the inability to stay on the Diary screen.
    private var diaryFeedViewModel: CircleDiaryFeedViewModel?
    /// Held only to forward to `CircleSettingsView` when constructed — this
    /// ViewModel never calls CloudKit APIs on it directly.
    let cloudSharingControllerProvider: CloudSharingControllerProviding

    /// `.task { loadIfNeeded() }`, `.onChange(of: scenePhase)` becoming
    /// `.active`, and a remote-change pulse from `observeRemoteChanges()`
    /// can all fire `refresh()` around the same moment — most notably at
    /// cold launch. Without coalescing, each overlapping call independently
    /// ran `SeedDemoCircleUseCase.execute()`, which is how a concurrent-
    /// seeding race could persist duplicate demo members. Overlapping
    /// callers now await the one in-flight refresh instead of starting a
    /// second one.
    private var inFlightRefresh: Task<Void, Never>?

    init(
        loadPetHomeUseCase: LoadPetHomeUseCase,
        loadTodayMomentsUseCase: LoadTodayMomentsUseCase,
        seedDemoCircleUseCase: SeedDemoCircleUseCase,
        publishDailyMomentUseCase: PublishDailyMomentUseCase,
        photoProcessingService: PhotoProcessingService,
        loadMomentDetailUseCase: LoadMomentDetailUseCase,
        addCommentUseCase: AddCommentUseCase,
        removeCommentUseCase: RemoveCommentUseCase,
        reactToMomentUseCase: ReactToMomentUseCase,
        reactToCommentUseCase: ReactToCommentUseCase,
        loadCircleMembersUseCase: LoadCircleMembersUseCase,
        checkCloudAccountUseCase: CheckCloudAccountUseCase,
        loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase,
        prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase,
        refreshSharedCircleUseCase: RefreshSharedCircleUseCase,
        loadActiveCircleInviteCodeUseCase: LoadActiveCircleInviteCodeUseCase,
        createCircleInviteCodeUseCase: CreateCircleInviteCodeUseCase,
        revokeCircleInviteCodeUseCase: RevokeCircleInviteCodeUseCase,
        resolveCircleInviteCodeUseCase: ResolveCircleInviteCodeUseCase,
        shareURLOpener: ShareURLOpening,
        remoteChangeSignal: RemoteChangeSignaling,
        cloudSyncEventSignal: CloudSyncEventSignaling,
        cloudSharingControllerProvider: CloudSharingControllerProviding,
        publishWidgetSnapshotUseCase: PublishWidgetSnapshotUseCase,
        importPendingSharesUseCase: ImportPendingSharesUseCase,
        loadPendingDraftsUseCase: LoadPendingDraftsUseCase,
        loadPendingDraftImageUseCase: LoadPendingDraftImageUseCase,
        consumePendingDraftUseCase: ConsumePendingDraftUseCase,
        simulateFriendCheckInUseCase: SimulateFriendCheckInUseCase,
        cleanUpLegacyDemoFriendUseCase: CleanUpLegacyDemoFriendUseCase,
        publishDiaryEntryUseCase: PublishDiaryEntryUseCase,
        loadActiveDiaryFeedUseCase: LoadActiveDiaryFeedUseCase,
        loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase,
        loadDiaryDetailUseCase: LoadDiaryDetailUseCase,
        addDiaryCommentUseCase: AddDiaryCommentUseCase,
        reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase,
        reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase,
        deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase,
        screenCaptureStateProviding: ScreenCaptureStateProviding,
        clock: ClockProviding
    ) {
        self.loadPetHomeUseCase = loadPetHomeUseCase
        self.loadTodayMomentsUseCase = loadTodayMomentsUseCase
        self.seedDemoCircleUseCase = seedDemoCircleUseCase
        self.publishDailyMomentUseCase = publishDailyMomentUseCase
        self.photoProcessingService = photoProcessingService
        self.loadMomentDetailUseCase = loadMomentDetailUseCase
        self.addCommentUseCase = addCommentUseCase
        self.removeCommentUseCase = removeCommentUseCase
        self.reactToMomentUseCase = reactToMomentUseCase
        self.reactToCommentUseCase = reactToCommentUseCase
        self.loadCircleMembersUseCase = loadCircleMembersUseCase
        self.checkCloudAccountUseCase = checkCloudAccountUseCase
        self.loadCircleSharingStateUseCase = loadCircleSharingStateUseCase
        self.prepareCircleInvitationUseCase = prepareCircleInvitationUseCase
        self.refreshSharedCircleUseCase = refreshSharedCircleUseCase
        self.loadActiveCircleInviteCodeUseCase = loadActiveCircleInviteCodeUseCase
        self.createCircleInviteCodeUseCase = createCircleInviteCodeUseCase
        self.revokeCircleInviteCodeUseCase = revokeCircleInviteCodeUseCase
        self.resolveCircleInviteCodeUseCase = resolveCircleInviteCodeUseCase
        self.shareURLOpener = shareURLOpener
        self.remoteChangeSignal = remoteChangeSignal
        self.cloudSyncEventSignal = cloudSyncEventSignal
        self.cloudSharingControllerProvider = cloudSharingControllerProvider
        self.publishWidgetSnapshotUseCase = publishWidgetSnapshotUseCase
        self.importPendingSharesUseCase = importPendingSharesUseCase
        self.loadPendingDraftsUseCase = loadPendingDraftsUseCase
        self.loadPendingDraftImageUseCase = loadPendingDraftImageUseCase
        self.consumePendingDraftUseCase = consumePendingDraftUseCase
        self.simulateFriendCheckInUseCase = simulateFriendCheckInUseCase
        self.cleanUpLegacyDemoFriendUseCase = cleanUpLegacyDemoFriendUseCase
        self.publishDiaryEntryUseCase = publishDiaryEntryUseCase
        self.loadActiveDiaryFeedUseCase = loadActiveDiaryFeedUseCase
        self.loadMyDiaryArchiveUseCase = loadMyDiaryArchiveUseCase
        self.loadDiaryDetailUseCase = loadDiaryDetailUseCase
        self.addDiaryCommentUseCase = addDiaryCommentUseCase
        self.reactToDiaryEntryUseCase = reactToDiaryEntryUseCase
        self.reactToDiaryCommentUseCase = reactToDiaryCommentUseCase
        self.deleteDiaryEntryUseCase = deleteDiaryEntryUseCase
        self.screenCaptureStateProviding = screenCaptureStateProviding
        self.clock = clock
    }

    /// Observes CloudKit sync evidence and remote-change pulses for the
    /// lifetime of the view. Never polls — purely reactive to platform
    /// notifications. Intended to run as a long-lived `.task`.
    func observeCloudSync() async {
        async let syncTask: Void = observeSyncEvents()
        async let remoteChangeTask: Void = observeRemoteChanges()
        _ = await (syncTask, remoteChangeTask)
    }

    private func observeSyncEvents() async {
        for await status in cloudSyncEventSignal.syncEvents() {
            syncStatus = status
        }
    }

    private func observeRemoteChanges() async {
        for await _ in remoteChangeSignal.remoteChanges() {
            _ = try? await refreshSharedCircleUseCase.execute()
            await refresh()
        }
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await refresh()
    }

    func refresh() async {
        if let inFlightRefresh {
            await inFlightRefresh.value
            return
        }
        let task = Task { await performRefresh() }
        inFlightRefresh = task
        await task.value
        inFlightRefresh = nil
    }

    private func performRefresh() async {
        loadState = .loading
        do {
            let seedResult = try await seedDemoCircleUseCase.execute()
            #if DEBUG
            // Narrowly-scoped, Debug-only cleanup for a known legacy bug
            // (see `CleanUpLegacyDemoFriendUseCase`) — never affects a real
            // member or any profile ID other than the one exact legacy ID.
            // Best-effort: a failure here never blocks the rest of refresh.
            try? await cleanUpLegacyDemoFriendUseCase.execute(circleID: seedResult.circle.id)
            #endif
            let snapshot = try await loadPetHomeUseCase.execute()
            self.snapshot = snapshot
            await publishWidgetSnapshotUseCase.execute(from: snapshot)

            await importPendingSharesUseCase.execute()
            pendingSharedDraft = (try? await loadPendingDraftsUseCase.execute())?.first

            if snapshot.canViewTodayFeed {
                do {
                    todayMoments = try await loadTodayMomentsUseCase.execute(
                        circleID: snapshot.circle.id,
                        requestingProfileID: snapshot.currentMember.profileID,
                        day: snapshot.today
                    )
                    feedError = nil
                } catch {
                    todayMoments = []
                    feedError = "Couldn't load your friends' moments. Pull to refresh to try again."
                }
            } else {
                todayMoments = []
                feedError = nil
            }

            loadState = .loaded
        } catch {
            loadState = .error(Self.message(for: error))
        }
    }

    /// Debug-only: runs `SimulateFriendCheckInUseCase` and reacts to its
    /// semantic result. Holds no business rules itself — the Use Case
    /// decides whether the current user has posted, whether the demo
    /// friend already checked in, and what "unavailable" means; this
    /// method only maps that result onto UI state and, after a genuinely
    /// new post, calls the existing refresh flow (which recalculates
    /// survival from persisted posts and republishes the Widget snapshot,
    /// exactly like any other post).
    func simulateFriendCheckIn() async {
        guard let snapshot else { return }
        demoCheckInState = .checkingIn
        do {
            let result = try await simulateFriendCheckInUseCase.execute(
                circle: snapshot.circle,
                currentMember: snapshot.currentMember
            )
            switch result {
            case .created:
                demoCheckInState = .idle
                await refresh()
            case .alreadyCheckedIn:
                demoCheckInState = .idle
            case .unavailable(let reason):
                demoCheckInState = .error(reason)
            }
        } catch {
            demoCheckInState = .error("We couldn't simulate Ava's check-in. Please try again.")
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

    func makeComposerViewModel() -> PostComposerViewModel? {
        guard let snapshot else { return nil }
        return PostComposerViewModel(
            circle: snapshot.circle,
            member: snapshot.currentMember,
            publishDailyMomentUseCase: publishDailyMomentUseCase,
            photoProcessingService: photoProcessingService
        )
    }

    /// Builds a composer prefilled with a shared photo the user hasn't
    /// finished posting yet — the same composer and publish workflow as
    /// `makeComposerViewModel()`, just seeded with the pending draft's
    /// image and caption instead of starting empty.
    func makeComposerViewModel(forPendingDraft draft: PendingPostDraft) -> PostComposerViewModel? {
        guard let snapshot else { return nil }
        let imageData = loadPendingDraftImageUseCase.execute(for: draft)
        return PostComposerViewModel(
            circle: snapshot.circle,
            member: snapshot.currentMember,
            publishDailyMomentUseCase: publishDailyMomentUseCase,
            photoProcessingService: photoProcessingService,
            prefilledImageData: imageData,
            prefilledCaption: draft.caption,
            pendingDraftID: draft.id,
            pendingDraftImageFilename: draft.localImagePath,
            consumePendingDraftUseCase: consumePendingDraftUseCase
        )
    }

    func makePostDetailViewModel(momentID: UUID) -> PostDetailViewModel? {
        guard let snapshot else { return nil }
        return PostDetailViewModel(
            momentID: momentID,
            currentMember: snapshot.currentMember,
            loadMomentDetailUseCase: loadMomentDetailUseCase,
            addCommentUseCase: addCommentUseCase,
            removeCommentUseCase: removeCommentUseCase,
            reactToMomentUseCase: reactToMomentUseCase,
            reactToCommentUseCase: reactToCommentUseCase
        )
    }

    func makeCircleSettingsViewModel() -> CircleSettingsViewModel {
        CircleSettingsViewModel(
            loadPetHomeUseCase: loadPetHomeUseCase,
            loadCircleMembersUseCase: loadCircleMembersUseCase,
            checkCloudAccountUseCase: checkCloudAccountUseCase,
            loadCircleSharingStateUseCase: loadCircleSharingStateUseCase,
            prepareCircleInvitationUseCase: prepareCircleInvitationUseCase,
            loadActiveCircleInviteCodeUseCase: loadActiveCircleInviteCodeUseCase,
            createCircleInviteCodeUseCase: createCircleInviteCodeUseCase,
            revokeCircleInviteCodeUseCase: revokeCircleInviteCodeUseCase,
            clock: clock
        )
    }

    /// Builds the Circle Diary feed — a separate, text-only social surface
    /// from the Daily Moment flow above. `nil` until the Circle snapshot has
    /// loaded, matching every other `make*ViewModel()` factory here.
    ///
    /// Returns the same memoized instance on every call after the first —
    /// see `diaryFeedViewModel`'s doc comment for why that stability matters
    /// for the `NavigationLink` that pushes it from `PetHomeView`.
    func makeCircleDiaryFeedViewModel() -> CircleDiaryFeedViewModel? {
        if let diaryFeedViewModel { return diaryFeedViewModel }
        guard let snapshot else { return nil }
        let viewModel = CircleDiaryFeedViewModel(
            circleID: snapshot.circle.id,
            currentMember: snapshot.currentMember,
            loadActiveDiaryFeedUseCase: loadActiveDiaryFeedUseCase,
            publishDiaryEntryUseCase: publishDiaryEntryUseCase,
            loadDiaryDetailUseCase: loadDiaryDetailUseCase,
            addDiaryCommentUseCase: addDiaryCommentUseCase,
            deleteDiaryEntryUseCase: deleteDiaryEntryUseCase,
            reactToDiaryEntryUseCase: reactToDiaryEntryUseCase,
            reactToDiaryCommentUseCase: reactToDiaryCommentUseCase,
            loadMyDiaryArchiveUseCase: loadMyDiaryArchiveUseCase,
            screenCaptureStateProviding: screenCaptureStateProviding,
            clock: clock
        )
        diaryFeedViewModel = viewModel
        return viewModel
    }

    func makeJoinCircleViewModel() -> JoinCircleViewModel {
        JoinCircleViewModel(
            resolveCircleInviteCodeUseCase: resolveCircleInviteCodeUseCase,
            shareURLOpener: shareURLOpener
        )
    }

    private static func message(for error: Error) -> String {
        if let domainError = error as? DomainError {
            switch domainError {
            case .circleNotFound: return "We couldn't find your Circle."
            case .memberNotFound: return "We couldn't find your profile in this Circle."
            case .petNotFound: return "Your pet is missing. Please try again."
            case .feedLocked: return "Post today's moment to unlock your friends' feed."
            case .momentNotFound, .commentNotFound, .notCommentAuthor, .pendingDraftCorrupted, .membershipFull,
                 .diaryEntryNotFound, .notDiaryEntryAuthor, .diaryCommentNotFound, .diaryEntryCorrupted:
                return "Something went wrong. Please try again."
            }
        }
        return "Something went wrong. Please try again."
    }
}
