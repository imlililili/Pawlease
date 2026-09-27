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

    private(set) var loadState: LoadState = .idle
    private(set) var snapshot: PetHomeSnapshot?
    private(set) var todayMoments: [DailyMoment] = []
    private(set) var feedError: String?
    private(set) var syncStatus: CircleSyncStatus = .localChangesSaved
    private(set) var pendingSharedDraft: PendingPostDraft?
    var isComposerPresented = false
    var isJoinCirclePresented = false

    var viewState: PetHomeViewState? {
        snapshot.map(PetHomeViewState.init)
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
    private let clock: ClockProviding
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
            _ = try await seedDemoCircleUseCase.execute()
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
            case .momentNotFound, .commentNotFound, .notCommentAuthor, .pendingDraftCorrupted, .membershipFull:
                return "Something went wrong. Please try again."
            }
        }
        return "Something went wrong. Please try again."
    }
}
