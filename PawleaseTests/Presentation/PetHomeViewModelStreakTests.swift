import Testing
import Foundation
import UIKit
@testable import Pawlease

/// Required streak test 9: `PetHomeViewModel` must display the recalculated
/// streak after the current member publishes their day-two moment — proving
/// correct behavior all the way up through the real publish →
/// `handleComposerDismissed` → `refresh()` flow, not just inside the Use
/// Case layer.
@MainActor
struct PetHomeViewModelStreakTests {
    private let timeZone = "America/Los_Angeles"

    private func makeViewModel(
        circleRepo: InMemoryCircleRepository,
        memberRepo: InMemoryMemberRepository,
        petRepo: InMemoryPetRepository,
        momentRepo: InMemoryMomentRepository,
        clock: ClockProviding
    ) -> PetHomeViewModel {
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
    func petHomeDisplaysTheRecalculatedStreakAfterDayTwoPublication() async throws {
        let circleID = DemoSeed.circleID
        let memberID = DemoSeed.currentProfileID
        let friendID = UUID()
        let day1 = TestFactories.date(year: 2026, month: 3, day: 14, hour: 20, timeZoneIdentifier: timeZone)
        let day2 = TestFactories.date(year: 2026, month: 3, day: 15, hour: 20, timeZoneIdentifier: timeZone)

        // Pre-seed fixed, known data — `SeedDemoCircleUseCase` is a no-op
        // once a default Circle already exists, so this fully controls the
        // Circle's time zone instead of depending on the test machine's.
        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(id: circleID, name: "Test Circle", timezoneIdentifier: timeZone, createdAt: day1, ownerProfileID: memberID)
        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            TestFactories.member(circleID: circleID, profileID: memberID, displayName: "You"),
            TestFactories.member(circleID: circleID, profileID: friendID, displayName: "Ava")
        ]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: day1)
        let momentRepo = InMemoryMomentRepository()

        let circleDay1 = CircleDay(date: day1, timeZoneIdentifier: timeZone)
        let circleDay2 = CircleDay(date: day2, timeZoneIdentifier: timeZone)

        // Day one already fully survived, persisted before this session
        // even starts — exactly like reopening the app on day two with
        // yesterday's history already on disk.
        momentRepo.moments = [
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleDay1, createdAt: day1),
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay1, createdAt: day1)
        ]

        let dayTwoViewModel = makeViewModel(circleRepo: circleRepo, memberRepo: memberRepo, petRepo: petRepo, momentRepo: momentRepo, clock: FakeClock(now: day2))
        await dayTwoViewModel.refresh()
        #expect(dayTwoViewModel.viewState?.streakDays == 1, "Day two hasn't been posted yet; only yesterday's already-survived day counts")

        // The current member publishes their day-two photo through the
        // real composer → publish → dismiss → refresh flow.
        let composer = dayTwoViewModel.makeComposerViewModel()
        composer?.setCapturedPhotoData(try makeSquareJPEGData())
        await composer?.publish()
        #expect(composer?.didPublish == true)
        await dayTwoViewModel.handleComposerDismissed(didPublish: composer?.didPublish ?? false)

        // A second, distinct contributor also posts on day two.
        momentRepo.moments.append(
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay2, createdAt: day2)
        )
        await dayTwoViewModel.refresh()

        #expect(dayTwoViewModel.viewState?.contributorPillLabel.hasPrefix("2/2") == true)
        #expect(dayTwoViewModel.viewState?.streakDays == 2, "Pet Home must show the recalculated 2-day streak after day two is published")
        #expect(dayTwoViewModel.viewState?.streakLabel == "2 days")
    }

    private func makeSquareJPEGData() throws -> Data {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            struct EncodingFailed: Error {}
            throw EncodingFailed()
        }
        return data
    }
}
