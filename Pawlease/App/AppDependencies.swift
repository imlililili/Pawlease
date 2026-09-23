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

    let photoProcessingService: PhotoProcessingService
    /// Infrastructure-layer adapter for the native sharing sheet. Held here
    /// (not on a ViewModel) and passed directly to the View that presents
    /// it, since CloudKit/UIKit types must never reach a ViewModel.
    let cloudSharingControllerProvider: CloudSharingControllerProviding

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
    let publishWidgetSnapshotUseCase: PublishWidgetSnapshotUseCase

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
        self.publishWidgetSnapshotUseCase = PublishWidgetSnapshotUseCase(
            widgetSnapshotStore: self.widgetSnapshotStore,
            widgetTimelineReloader: self.widgetTimelineReloader,
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
