import Testing
import Foundation
@testable import Pawlease

/// Regression coverage for the invite-code error-presentation bug: an
/// unavailable iCloud account surfaces as `CircleSharingError` (thrown by
/// `PrepareCircleInvitationUseCase`, inside `CreateCircleInviteCodeUseCase`)
/// — not `CircleInviteCodeError` — and `createInviteCode()`'s catch clauses
/// must handle both, or the account-unavailable case silently falls back to
/// a generic message.
@MainActor
struct CircleSettingsViewModelTests {
    private func makeViewModel(
        clock: ClockProviding,
        accountProvider: MockCloudAccountStatusProvider,
        sharingRepository: MockCircleSharingRepository
    ) -> (CircleSettingsViewModel, UUID) {
        let circleID = UUID()
        let memberID = UUID()

        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(
            id: circleID, name: "Test Circle", timezoneIdentifier: "UTC", createdAt: clock.now, ownerProfileID: memberID
        )
        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            CircleMember(id: UUID(), circleID: circleID, profileID: memberID, displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)
        ]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: clock.now)
        let momentRepo = InMemoryMomentRepository()

        let loadPetHomeUseCase = LoadPetHomeUseCase(
            circleRepository: circleRepo, memberRepository: memberRepo, petRepository: petRepo,
            momentRepository: momentRepo, clock: clock, currentProfileID: memberID
        )
        let prepareInvitationUseCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: accountProvider, circleSharingRepository: sharingRepository
        )
        let inviteCodeRepo = MockCircleInviteCodeRepository()

        let viewModel = CircleSettingsViewModel(
            loadPetHomeUseCase: loadPetHomeUseCase,
            loadCircleMembersUseCase: LoadCircleMembersUseCase(memberRepository: memberRepo),
            checkCloudAccountUseCase: CheckCloudAccountUseCase(cloudAccountStatusProvider: accountProvider),
            loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase(circleSharingRepository: sharingRepository),
            prepareCircleInvitationUseCase: prepareInvitationUseCase,
            loadActiveCircleInviteCodeUseCase: LoadActiveCircleInviteCodeUseCase(circleInviteCodeRepository: inviteCodeRepo),
            createCircleInviteCodeUseCase: CreateCircleInviteCodeUseCase(
                prepareCircleInvitationUseCase: prepareInvitationUseCase,
                circleInviteCodeRepository: inviteCodeRepo,
                clock: clock
            ),
            revokeCircleInviteCodeUseCase: RevokeCircleInviteCodeUseCase(circleInviteCodeRepository: inviteCodeRepo),
            clock: clock
        )
        return (viewModel, circleID)
    }

    @Test
    func noAccountShowsAnExplicitSignInMessage() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .noAccount
        let (viewModel, _) = makeViewModel(clock: clock, accountProvider: accountProvider, sharingRepository: MockCircleSharingRepository())

        await viewModel.refresh()
        await viewModel.createInviteCode()

        #expect(viewModel.inviteCodeState == .error("Sign in to iCloud in Settings to create an invite code."))
    }

    @Test
    func restrictedAccountShowsAnActionableMessage() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .restricted
        let (viewModel, _) = makeViewModel(clock: clock, accountProvider: accountProvider, sharingRepository: MockCircleSharingRepository())

        await viewModel.refresh()
        await viewModel.createInviteCode()

        #expect(viewModel.inviteCodeState == .error("iCloud is restricted on this device, so you can't create an invite code right now."))
    }

    @Test
    func couldNotDetermineAccountShowsAnActionableMessage() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .unknown // maps from CKAccountStatus.couldNotDetermine
        let (viewModel, _) = makeViewModel(clock: clock, accountProvider: accountProvider, sharingRepository: MockCircleSharingRepository())

        await viewModel.refresh()
        await viewModel.createInviteCode()

        #expect(viewModel.inviteCodeState == .error("We couldn't check your iCloud status. Please try again."))
    }

    @Test
    func transientNetworkFailurePreservesItsRetryableMessage() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .available
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareError = CircleSharingError.networkUnavailable
        let (viewModel, _) = makeViewModel(clock: clock, accountProvider: accountProvider, sharingRepository: sharingRepository)

        await viewModel.refresh()
        await viewModel.createInviteCode()

        #expect(viewModel.inviteCodeState == .error(CircleSharingError.networkUnavailable.displayMessage))
    }
}
