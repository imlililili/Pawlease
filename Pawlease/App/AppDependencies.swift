import Foundation

/// Composition root: constructs the persistence stack, concrete
/// repositories, and Use Cases, and wires them together. Views receive only
/// what they need to build ViewModels — never Core Data or CloudKit types.
@MainActor
final class AppDependencies {
    let persistenceController: PersistenceController
    let clock: ClockProviding
    let currentProfileID: UUID

    let circleRepository: CircleRepository
    let memberRepository: MemberRepository
    let petRepository: PetRepository
    let momentRepository: MomentRepository
    let commentRepository: CommentRepository
    let momentReactionRepository: MomentReactionRepository
    let commentReactionRepository: CommentReactionRepository
    let cloudAccountStatusProvider: CloudAccountStatusProviding
    let circleSharingRepository: CircleSharingRepository
    let remoteChangeSignal: RemoteChangeSignaling
    let cloudSyncEventSignal: CloudSyncEventSignaling
    let widgetSnapshotStore: WidgetSnapshotStoring
    let widgetTimelineReloader: WidgetTimelineReloading
    let pendingPostDraftRepository: PendingPostDraftRepository
    let shareInboxStore: ShareInboxStoring
    let userProfileRepository: UserProfileRepository
    let circleInviteCodeRepository: CircleInviteCodeRepository
    let diaryEntryRepository: DiaryEntryRepository
    let diaryCommentRepository: DiaryCommentRepository
    let diaryReactionRepository: DiaryReactionRepository
    let diaryCommentReactionRepository: DiaryCommentReactionRepository

    let photoProcessingService: PhotoProcessingService
    /// Infrastructure-layer adapter for the native sharing sheet. Held here
    /// (not on a ViewModel) and passed directly to the View that presents
    /// it, since CloudKit/UIKit types must never reach a ViewModel.
    let cloudSharingControllerProvider: CloudSharingControllerProviding
    /// Infrastructure-layer adapter that opens a resolved CKShare URL — the
    /// Join-a-Circle counterpart to `cloudSharingControllerProvider`. Held
    /// here and passed to the ViewModel that needs it (never a Use Case).
    let shareURLOpener: ShareURLOpening
    /// Infrastructure-layer adapter for screen-recording/AirPlay/mirroring
    /// and screenshot detection, behind `ScreenCaptureStateProviding` so
    /// Presentation logic is testable without `UIScreen`/`UIApplication`.
    let screenCaptureStateProviding: ScreenCaptureStateProviding

    let seedDemoCircleUseCase: SeedDemoCircleUseCase
    let loadPetHomeUseCase: LoadPetHomeUseCase
    let loadTodayMomentsUseCase: LoadTodayMomentsUseCase
    let publishDailyMomentUseCase: PublishDailyMomentUseCase
    let loadMomentDetailUseCase: LoadMomentDetailUseCase
    let addCommentUseCase: AddCommentUseCase
    let removeCommentUseCase: RemoveCommentUseCase
    let reactToMomentUseCase: ReactToMomentUseCase
    let reactToCommentUseCase: ReactToCommentUseCase
    let checkCloudAccountUseCase: CheckCloudAccountUseCase
    let prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase
    let acceptCircleInvitationUseCase: AcceptCircleInvitationUseCase
    let loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase
    let refreshSharedCircleUseCase: RefreshSharedCircleUseCase
    let loadCircleMembersUseCase: LoadCircleMembersUseCase
    let createCircleInviteCodeUseCase: CreateCircleInviteCodeUseCase
    let resolveCircleInviteCodeUseCase: ResolveCircleInviteCodeUseCase
    let revokeCircleInviteCodeUseCase: RevokeCircleInviteCodeUseCase
    let loadActiveCircleInviteCodeUseCase: LoadActiveCircleInviteCodeUseCase
    let completeJoinedCircleMembershipUseCase: CompleteJoinedCircleMembershipUseCase
    let publishWidgetSnapshotUseCase: PublishWidgetSnapshotUseCase
    let importPendingSharesUseCase: ImportPendingSharesUseCase
    let loadPendingDraftsUseCase: LoadPendingDraftsUseCase
    let loadPendingDraftImageUseCase: LoadPendingDraftImageUseCase
    let consumePendingDraftUseCase: ConsumePendingDraftUseCase
    /// Debug-only demo workflow — see `SimulateFriendCheckInUseCase`. Always
    /// constructed (so `PetHomeViewModel`'s shape stays stable across
    /// configurations); `PetHomeView` gates the UI entry point behind
    /// `#if DEBUG`, so this never runs in a Release build.
    let simulateFriendCheckInUseCase: SimulateFriendCheckInUseCase
    /// Debug-only — see `CleanUpLegacyDemoFriendUseCase`. Always
    /// constructed like `simulateFriendCheckInUseCase`; only its call site
    /// in `PetHomeViewModel.performRefresh()` is `#if DEBUG`-gated.
    let cleanUpLegacyDemoFriendUseCase: CleanUpLegacyDemoFriendUseCase

    let publishDiaryEntryUseCase: PublishDiaryEntryUseCase
    let loadActiveDiaryFeedUseCase: LoadActiveDiaryFeedUseCase
    let loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase
    let loadDiaryDetailUseCase: LoadDiaryDetailUseCase
    let addDiaryCommentUseCase: AddDiaryCommentUseCase
    let reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase
    let reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase
    let deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase

    init(
        persistenceController: PersistenceController,
        clock: ClockProviding = SystemClock(),
        currentProfileID: UUID = DemoSeed.currentProfileID
    ) {
        self.persistenceController = persistenceController
        self.clock = clock
        self.currentProfileID = currentProfileID
        self.photoProcessingService = PhotoProcessingService()

        let container = persistenceController.container
        let circleRepo = CoreDataCircleRepository(container: container)
        let memberRepo = CoreDataMemberRepository(container: container)
        let petRepo = CoreDataPetRepository(container: container)
        let momentRepo = CoreDataMomentRepository(container: container)
        let commentRepo = CoreDataCommentRepository(container: container)
        let momentReactionRepo = CoreDataMomentReactionRepository(container: container)
        let commentReactionRepo = CoreDataCommentReactionRepository(container: container)

        self.circleRepository = circleRepo
        self.memberRepository = memberRepo
        self.petRepository = petRepo
        self.momentRepository = momentRepo
        self.commentRepository = commentRepo
        self.momentReactionRepository = momentReactionRepo
        self.commentReactionRepository = commentReactionRepo

        let cloudAccountStatus = CloudKitAccountStatusProvider()
        let circleSharingRepo = CloudKitCircleSharingRepository(
            container: container,
            shareAcceptanceCoordinator: .shared
        )
        self.cloudAccountStatusProvider = cloudAccountStatus
        self.circleSharingRepository = circleSharingRepo
        self.remoteChangeSignal = CoreDataRemoteChangeSignal(container: container)
        self.cloudSyncEventSignal = CoreDataCloudSyncEventSignal(container: container)
        self.cloudSharingControllerProvider = CloudKitSharingControllerProvider(container: container)
        self.widgetSnapshotStore = AppGroupWidgetSnapshotStore()
        self.widgetTimelineReloader = WidgetKitTimelineReloader()
        let pendingDraftRepo = CoreDataPendingPostDraftRepository(container: container)
        self.pendingPostDraftRepository = pendingDraftRepo
        self.shareInboxStore = AppGroupShareInboxStore()
        let userProfileRepo = CoreDataUserProfileRepository(container: container, clock: clock)
        self.userProfileRepository = userProfileRepo
        let circleInviteCodeRepo = CloudKitCircleInviteCodeRepository()
        self.circleInviteCodeRepository = circleInviteCodeRepo
        self.shareURLOpener = SystemShareURLOpener()
        self.screenCaptureStateProviding = SystemScreenCaptureStateProvider()

        let diaryEntryRepo = CoreDataDiaryEntryRepository(container: container)
        let diaryCommentRepo = CoreDataDiaryCommentRepository(container: container)
        let diaryReactionRepo = CoreDataDiaryReactionRepository(container: container)
        let diaryCommentReactionRepo = CoreDataDiaryCommentReactionRepository(container: container)
        self.diaryEntryRepository = diaryEntryRepo
        self.diaryCommentRepository = diaryCommentRepo
        self.diaryReactionRepository = diaryReactionRepo
        self.diaryCommentReactionRepository = diaryCommentReactionRepo

        self.seedDemoCircleUseCase = SeedDemoCircleUseCase(
            circleRepository: circleRepo,
            memberRepository: memberRepo,
            petRepository: petRepo,
            clock: clock
        )
        self.loadPetHomeUseCase = LoadPetHomeUseCase(
            circleRepository: circleRepo,
            memberRepository: memberRepo,
            petRepository: petRepo,
            momentRepository: momentRepo,
            clock: clock,
            currentProfileID: currentProfileID
        )
        self.loadTodayMomentsUseCase = LoadTodayMomentsUseCase(momentRepository: momentRepo)
        self.publishDailyMomentUseCase = PublishDailyMomentUseCase(
            momentRepository: momentRepo,
            clock: clock
        )
        self.loadMomentDetailUseCase = LoadMomentDetailUseCase(
            momentRepository: momentRepo,
            commentRepository: commentRepo,
            momentReactionRepository: momentReactionRepo,
            commentReactionRepository: commentReactionRepo
        )
        self.addCommentUseCase = AddCommentUseCase(
            commentRepository: commentRepo,
            momentRepository: momentRepo,
            clock: clock
        )
        self.removeCommentUseCase = RemoveCommentUseCase(commentRepository: commentRepo)
        self.reactToMomentUseCase = ReactToMomentUseCase(
            momentReactionRepository: momentReactionRepo,
            clock: clock
        )
        self.reactToCommentUseCase = ReactToCommentUseCase(
            commentReactionRepository: commentReactionRepo,
            clock: clock
        )
        self.checkCloudAccountUseCase = CheckCloudAccountUseCase(
            cloudAccountStatusProvider: cloudAccountStatus
        )
        self.prepareCircleInvitationUseCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: cloudAccountStatus,
            circleSharingRepository: circleSharingRepo
        )
        self.acceptCircleInvitationUseCase = AcceptCircleInvitationUseCase(
            circleSharingRepository: circleSharingRepo
        )
        self.loadCircleSharingStateUseCase = LoadCircleSharingStateUseCase(
            circleSharingRepository: circleSharingRepo
        )
        self.refreshSharedCircleUseCase = RefreshSharedCircleUseCase(
            loadPetHomeUseCase: self.loadPetHomeUseCase
        )
        self.loadCircleMembersUseCase = LoadCircleMembersUseCase(memberRepository: memberRepo)
        self.createCircleInviteCodeUseCase = CreateCircleInviteCodeUseCase(
            prepareCircleInvitationUseCase: self.prepareCircleInvitationUseCase,
            circleInviteCodeRepository: circleInviteCodeRepo,
            clock: clock
        )
        self.resolveCircleInviteCodeUseCase = ResolveCircleInviteCodeUseCase(
            circleInviteCodeRepository: circleInviteCodeRepo,
            clock: clock
        )
        self.revokeCircleInviteCodeUseCase = RevokeCircleInviteCodeUseCase(circleInviteCodeRepository: circleInviteCodeRepo)
        self.loadActiveCircleInviteCodeUseCase = LoadActiveCircleInviteCodeUseCase(circleInviteCodeRepository: circleInviteCodeRepo)
        self.completeJoinedCircleMembershipUseCase = CompleteJoinedCircleMembershipUseCase(
            circleRepository: circleRepo,
            memberRepository: memberRepo,
            userProfileRepository: userProfileRepo,
            clock: clock
        )
        self.publishWidgetSnapshotUseCase = PublishWidgetSnapshotUseCase(
            widgetSnapshotStore: self.widgetSnapshotStore,
            widgetTimelineReloader: self.widgetTimelineReloader,
            clock: clock
        )
        self.importPendingSharesUseCase = ImportPendingSharesUseCase(
            shareInboxStore: self.shareInboxStore,
            pendingPostDraftRepository: pendingDraftRepo
        )
        self.loadPendingDraftsUseCase = LoadPendingDraftsUseCase(pendingPostDraftRepository: pendingDraftRepo)
        self.loadPendingDraftImageUseCase = LoadPendingDraftImageUseCase(shareInboxStore: self.shareInboxStore)
        self.consumePendingDraftUseCase = ConsumePendingDraftUseCase(
            pendingPostDraftRepository: pendingDraftRepo,
            shareInboxStore: self.shareInboxStore
        )
        self.simulateFriendCheckInUseCase = SimulateFriendCheckInUseCase(
            memberRepository: memberRepo,
            momentRepository: momentRepo,
            publishDailyMomentUseCase: self.publishDailyMomentUseCase,
            photoProcessingService: self.photoProcessingService,
            demoImageProvider: BundledDemoCheckInImageProvider(),
            clock: clock
        )
        self.cleanUpLegacyDemoFriendUseCase = CleanUpLegacyDemoFriendUseCase(
            memberRepository: memberRepo,
            momentRepository: momentRepo
        )

        self.publishDiaryEntryUseCase = PublishDiaryEntryUseCase(
            diaryEntryRepository: diaryEntryRepo,
            clock: clock
        )
        self.loadActiveDiaryFeedUseCase = LoadActiveDiaryFeedUseCase(
            diaryEntryRepository: diaryEntryRepo,
            diaryCommentRepository: diaryCommentRepo,
            diaryReactionRepository: diaryReactionRepo,
            clock: clock
        )
        self.loadMyDiaryArchiveUseCase = LoadMyDiaryArchiveUseCase(
            diaryEntryRepository: diaryEntryRepo,
            clock: clock
        )
        self.loadDiaryDetailUseCase = LoadDiaryDetailUseCase(
            diaryEntryRepository: diaryEntryRepo,
            diaryCommentRepository: diaryCommentRepo,
            diaryReactionRepository: diaryReactionRepo,
            diaryCommentReactionRepository: diaryCommentReactionRepo
        )
        self.addDiaryCommentUseCase = AddDiaryCommentUseCase(
            diaryCommentRepository: diaryCommentRepo,
            diaryEntryRepository: diaryEntryRepo,
            clock: clock
        )
        self.reactToDiaryEntryUseCase = ReactToDiaryEntryUseCase(
            diaryReactionRepository: diaryReactionRepo,
            clock: clock
        )
        self.reactToDiaryCommentUseCase = ReactToDiaryCommentUseCase(
            diaryCommentReactionRepository: diaryCommentReactionRepo,
            clock: clock
        )
        self.deleteDiaryEntryUseCase = DeleteDiaryEntryUseCase(
            diaryEntryRepository: diaryEntryRepo,
            clock: clock
        )
    }

    static func live() -> AppDependencies {
        AppDependencies(persistenceController: .shared)
    }

    static func preview() -> AppDependencies {
        AppDependencies(persistenceController: .preview)
    }
}
