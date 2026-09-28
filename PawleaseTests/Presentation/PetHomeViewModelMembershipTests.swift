import Testing
import Foundation
@testable import Pawlease

/// Regression coverage for the Circle Settings duplicate-member bug's
/// actual trigger: `.task { loadIfNeeded() }`, `.onChange(of: scenePhase)`
/// becoming `.active`, and a remote-change pulse can all call
/// `PetHomeViewModel.refresh()` around the same moment — most notably at
/// cold launch. Before the fix, each overlapping call independently ran
/// `SeedDemoCircleUseCase.execute()`. This drives many concurrent
/// `refresh()` calls against the real Core Data stack and proves the
/// ViewModel's coalescing guard, together with the repository-level fix,
/// leaves exactly the three seeded members behind.
@MainActor
struct PetHomeViewModelMembershipTests {
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
    func concurrentRefreshCallsNeverCreateDuplicateMembers() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let clock = SystemClock()
        let viewModel = makeViewModel(container: persistence, clock: clock)

        // Reproduces the real trigger: `.task`, `.onChange(of: scenePhase)`,
        // and a remote-change pulse can all call `refresh()` at once.
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { await viewModel.refresh() }
            }
        }

        #expect(viewModel.loadState == .loaded)

        let memberRepo = CoreDataMemberRepository(container: persistence.container)
        let members = try await memberRepo.fetchMembers(circleID: DemoSeed.circleID)
        #expect(members.count == 3)
        #expect(Set(members.map(\.profileID)) == Set(DemoSeed.memberProfileIDs))
    }

    /// Reproduces the exact reported bug — Circle Settings showing "You,
    /// Ava, Noah, Ava" — by seeding a store that already has a legacy
    /// `CleanUpLegacyDemoFriendUseCase.legacyAvaProfileID` row alongside
    /// the normal three seeded members, then proving a single `refresh()`
    /// leaves exactly the three seeded members (Debug-only cleanup runs
    /// inside `performRefresh()`).
    @Test
    func refreshCleansUpAPreExistingLegacyAvaRow() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let clock = SystemClock()
        let memberRepo = CoreDataMemberRepository(container: persistence.container)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let petRepo = CoreDataPetRepository(container: persistence.container)

        // Seed the normal Circle first, then simulate the historical bug:
        // a fourth member under the legacy, unseeded "Ava" profile ID.
        _ = try await SeedDemoCircleUseCase(
            circleRepository: circleRepo, memberRepository: memberRepo, petRepository: petRepo, clock: clock
        ).execute()
        try await memberRepo.saveMember(CircleMember(
            id: UUID(), circleID: DemoSeed.circleID, profileID: CleanUpLegacyDemoFriendUseCase.legacyAvaProfileID,
            displayName: "Ava", avatarEmoji: "🌼", joinedAt: clock.now, role: .member
        ))
        let beforeCleanup = try await memberRepo.fetchMembers(circleID: DemoSeed.circleID)
        #expect(beforeCleanup.count == 4) // reproduces "You, Ava, Noah, Ava"

        let viewModel = makeViewModel(container: persistence, clock: clock)
        await viewModel.refresh()

        let members = try await memberRepo.fetchMembers(circleID: DemoSeed.circleID)
        #expect(members.count == 3)
        #expect(Set(members.map(\.profileID)) == Set(DemoSeed.memberProfileIDs))
        #expect(!members.contains { $0.profileID == CleanUpLegacyDemoFriendUseCase.legacyAvaProfileID })
    }
}
