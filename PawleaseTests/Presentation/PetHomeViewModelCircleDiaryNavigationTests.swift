import Testing
import Foundation
@testable import Pawlease

/// Regression coverage for Bug 2 (Circle Diary "infinite navigation"). The
/// confirmed root cause: `PetHomeView` pushes `CircleDiaryFeedView` via a
/// closure-based `NavigationLink`, which reconstructs its destination
/// eagerly every time `PetHomeView.body` re-evaluates (remote-change
/// pulses, cloud sync events, scene-phase changes). Before the fix,
/// `makeCircleDiaryFeedViewModel()` built a *brand-new*
/// `CircleDiaryFeedViewModel` on every call, so every such re-render handed
/// the `NavigationLink` a fresh destination identity while the user might
/// already be pushed into it — which is exactly what produced the
/// "navigationDestination... declared earlier on the stack" warning and the
/// inability to remain on the Diary screen. `makeCircleDiaryFeedViewModel()`
/// now memoizes and returns the same instance on every subsequent call;
/// this proves that directly, independent of any UI automation.
@MainActor
struct PetHomeViewModelCircleDiaryNavigationTests {
    private func makeViewModel(container: PersistenceController, clock: ClockProviding) -> PetHomeViewModel {
        let circleRepo = CoreDataCircleRepository(container: container.container)
        let memberRepo = CoreDataMemberRepository(container: container.container)
        let petRepo = CoreDataPetRepository(container: container.container)
        let momentRepo = InMemoryMomentRepository()

        let loadPetHomeUseCase = LoadPetHomeUseCase(
            circleRepository: circleRepo, memberRepository: memberRepo, petRepository: petRepo,
            momentRepository: momentRepo, clock: clock, currentProfileID: DemoSeed.currentProfileID
        )
        let accountProvider = MockCloudAccountStatusProvider()
        let sharingRepo = MockCircleSharingRepository()
        let inviteCodeRepo = MockCircleInviteCodeRepository()
        let pendingDraftRepo = MockPendingPostDraftRepository()
        let shareInboxStore = MockShareInboxStore()
        let prepareInvitationUseCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: accountProvider, circleSharingRepository: sharingRepo
        )
        let publishDailyMomentUseCase = PublishDailyMomentUseCase(momentRepository: momentRepo, clock: clock)
        let photoProcessingService = PhotoProcessingService()

        let diaryEntryRepo = InMemoryDiaryEntryRepository()
        let diaryCommentRepo = InMemoryDiaryCommentRepository()
        let diaryReactionRepo = InMemoryDiaryReactionRepository()
        let diaryCommentReactionRepo = InMemoryDiaryCommentReactionRepository()

        return PetHomeViewModel(
            loadPetHomeUseCase: loadPetHomeUseCase,
            loadTodayMomentsUseCase: LoadTodayMomentsUseCase(momentRepository: momentRepo),
            seedDemoCircleUseCase: SeedDemoCircleUseCase(
                circleRepository: circleRepo, memberRepository: memberRepo, petRepository: petRepo, clock: clock
            ),
            publishDailyMomentUseCase: publishDailyMomentUseCase,
            photoProcessingService: photoProcessingService,
            loadMomentDetailUseCase: LoadMomentDetailUseCase(
                momentRepository: momentRepo,
                commentRepository: MockCommentRepository(),
                momentReactionRepository: MockMomentReactionRepository(),
                commentReactionRepository: MockCommentReactionRepository()
            ),
            addCommentUseCase: AddCommentUseCase(commentRepository: MockCommentRepository(), momentRepository: momentRepo, clock: clock),
            removeCommentUseCase: RemoveCommentUseCase(commentRepository: MockCommentRepository()),
            reactToMomentUseCase: ReactToMomentUseCase(momentReactionRepository: MockMomentReactionRepository(), clock: clock),
            reactToCommentUseCase: ReactToCommentUseCase(commentReactionRepository: MockCommentReactionRepository(), clock: clock),
            loadCircleMembersUseCase: LoadCircleMembersUseCase(memberRepository: memberRepo),
            checkCloudAccountUseCase: CheckCloudAccountUseCase(cloudAccountStatusProvider: accountProvider),
            loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase(circleSharingRepository: sharingRepo),
            prepareCircleInvitationUseCase: prepareInvitationUseCase,
            refreshSharedCircleUseCase: RefreshSharedCircleUseCase(loadPetHomeUseCase: loadPetHomeUseCase),
            loadActiveCircleInviteCodeUseCase: LoadActiveCircleInviteCodeUseCase(circleInviteCodeRepository: inviteCodeRepo),
            createCircleInviteCodeUseCase: CreateCircleInviteCodeUseCase(
                prepareCircleInvitationUseCase: prepareInvitationUseCase,
                circleInviteCodeRepository: inviteCodeRepo,
                clock: clock
            ),
            revokeCircleInviteCodeUseCase: RevokeCircleInviteCodeUseCase(circleInviteCodeRepository: inviteCodeRepo),
            resolveCircleInviteCodeUseCase: ResolveCircleInviteCodeUseCase(circleInviteCodeRepository: inviteCodeRepo, clock: clock),
            shareURLOpener: NoOpShareURLOpener(),
            remoteChangeSignal: NoOpRemoteChangeSignal(),
            cloudSyncEventSignal: NoOpCloudSyncEventSignal(),
            cloudSharingControllerProvider: NoOpCloudSharingControllerProvider(),
            publishWidgetSnapshotUseCase: PublishWidgetSnapshotUseCase(
                widgetSnapshotStore: MockWidgetSnapshotStore(), widgetTimelineReloader: MockWidgetTimelineReloader(), clock: clock
            ),
            importPendingSharesUseCase: ImportPendingSharesUseCase(shareInboxStore: shareInboxStore, pendingPostDraftRepository: pendingDraftRepo),
            loadPendingDraftsUseCase: LoadPendingDraftsUseCase(pendingPostDraftRepository: pendingDraftRepo),
            loadPendingDraftImageUseCase: LoadPendingDraftImageUseCase(shareInboxStore: shareInboxStore),
            consumePendingDraftUseCase: ConsumePendingDraftUseCase(pendingPostDraftRepository: pendingDraftRepo, shareInboxStore: shareInboxStore),
            simulateFriendCheckInUseCase: SimulateFriendCheckInUseCase(
                memberRepository: memberRepo,
                momentRepository: momentRepo,
                publishDailyMomentUseCase: publishDailyMomentUseCase,
                photoProcessingService: photoProcessingService,
                demoImageProvider: MockDemoCheckInImageProvider(),
                clock: clock
            ),
            cleanUpLegacyDemoFriendUseCase: CleanUpLegacyDemoFriendUseCase(
                memberRepository: memberRepo,
                momentRepository: momentRepo
            ),
            publishDiaryEntryUseCase: PublishDiaryEntryUseCase(diaryEntryRepository: diaryEntryRepo, clock: clock),
            loadActiveDiaryFeedUseCase: LoadActiveDiaryFeedUseCase(
                diaryEntryRepository: diaryEntryRepo, diaryCommentRepository: diaryCommentRepo,
                diaryReactionRepository: diaryReactionRepo, clock: clock
            ),
            loadMyDiaryArchiveUseCase: LoadMyDiaryArchiveUseCase(diaryEntryRepository: diaryEntryRepo, clock: clock),
            loadDiaryDetailUseCase: LoadDiaryDetailUseCase(
                diaryEntryRepository: diaryEntryRepo, diaryCommentRepository: diaryCommentRepo,
                diaryReactionRepository: diaryReactionRepo, diaryCommentReactionRepository: diaryCommentReactionRepo
            ),
            addDiaryCommentUseCase: AddDiaryCommentUseCase(
                diaryCommentRepository: diaryCommentRepo, diaryEntryRepository: diaryEntryRepo, clock: clock
            ),
            reactToDiaryEntryUseCase: ReactToDiaryEntryUseCase(diaryReactionRepository: diaryReactionRepo, clock: clock),
            reactToDiaryCommentUseCase: ReactToDiaryCommentUseCase(diaryCommentReactionRepository: diaryCommentReactionRepo, clock: clock),
            deleteDiaryEntryUseCase: DeleteDiaryEntryUseCase(diaryEntryRepository: diaryEntryRepo, clock: clock),
            screenCaptureStateProviding: MockScreenCaptureStateProvider(),
            clock: clock
        )
    }

    @Test
    func makeCircleDiaryFeedViewModelReturnsTheSameInstanceOnRepeatedCalls() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let clock = SystemClock()
        let viewModel = makeViewModel(container: persistence, clock: clock)
        await viewModel.refresh()

        let first = viewModel.makeCircleDiaryFeedViewModel()
        let second = viewModel.makeCircleDiaryFeedViewModel()
        let third = viewModel.makeCircleDiaryFeedViewModel()

        let firstIdentity = try #require(first.map(ObjectIdentifier.init))
        #expect(second.map(ObjectIdentifier.init) == firstIdentity)
        #expect(third.map(ObjectIdentifier.init) == firstIdentity)
    }

    @Test
    func makeCircleDiaryFeedViewModelStaysStableAcrossUnrelatedRefreshes() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let clock = SystemClock()
        let viewModel = makeViewModel(container: persistence, clock: clock)
        await viewModel.refresh()

        let beforeExtraRefreshes = try #require(viewModel.makeCircleDiaryFeedViewModel())

        // Simulate the ancestor re-renders that used to reconstruct the
        // destination while the user was already pushed into it: repeated
        // `refresh()` calls, exactly what `observeRemoteChanges()` triggers
        // on every remote-change pulse.
        await viewModel.refresh()
        await viewModel.refresh()
        await viewModel.refresh()

        let afterExtraRefreshes = try #require(viewModel.makeCircleDiaryFeedViewModel())
        #expect(ObjectIdentifier(afterExtraRefreshes) == ObjectIdentifier(beforeExtraRefreshes))
    }
}
