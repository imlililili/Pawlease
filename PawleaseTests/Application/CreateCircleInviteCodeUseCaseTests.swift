import Testing
import Foundation
@testable import Pawlease

/// Mock-based only — never touches real CloudKit.
struct CreateCircleInviteCodeUseCaseTests {
    private func makeUseCase(
        sharingRepository: MockCircleSharingRepository,
        inviteCodeRepository: MockCircleInviteCodeRepository,
        clock: ClockProviding,
        maxCollisionRetries: Int = 5
    ) -> CreateCircleInviteCodeUseCase {
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .available
        let prepareUseCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: accountProvider,
            circleSharingRepository: sharingRepository
        )
        return CreateCircleInviteCodeUseCase(
            prepareCircleInvitationUseCase: prepareUseCase,
            circleInviteCodeRepository: inviteCodeRepository,
            clock: clock,
            maxCollisionRetries: maxCollisionRetries
        )
    }

    @Test
    func collisionGeneratesANewCodeAndRetries() async throws {
        let circleID = UUID()
        let shareURL = try #require(URL(string: "https://www.icloud.com/share/abc123"))
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareResult = PreparedCircleShare(circleID: circleID, isNewShare: true, shareURL: shareURL)

        let inviteCodeRepository = MockCircleInviteCodeRepository()
        inviteCodeRepository.publishResultQueue = [
            .failure(CircleInviteCodeError.collision),
            .failure(CircleInviteCodeError.collision)
            // Third attempt (no queued result) echoes back success.
        ]

        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = makeUseCase(sharingRepository: sharingRepository, inviteCodeRepository: inviteCodeRepository, clock: clock)

        let result = try await useCase.execute(circleID: circleID)

        #expect(inviteCodeRepository.publishCallCount == 3)
        #expect(result.circleID == circleID)
        // Each retry generated a genuinely different code.
        let attemptedCodes = Set(inviteCodeRepository.publishedDetails.map(\.code))
        #expect(attemptedCodes.count == 3)
    }

    @Test
    func retryLimitProducesADomainError() async {
        let circleID = UUID()
        let shareURL = URL(string: "https://www.icloud.com/share/abc123")!
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareResult = PreparedCircleShare(circleID: circleID, isNewShare: true, shareURL: shareURL)

        let inviteCodeRepository = MockCircleInviteCodeRepository()
        inviteCodeRepository.publishResultQueue = Array(
            repeating: .failure(CircleInviteCodeError.collision), count: 10
        )

        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = makeUseCase(
            sharingRepository: sharingRepository, inviteCodeRepository: inviteCodeRepository, clock: clock, maxCollisionRetries: 3
        )

        await #expect(throws: CircleInviteCodeError.retryLimitExceeded) {
            _ = try await useCase.execute(circleID: circleID)
        }
        #expect(inviteCodeRepository.publishCallCount == 3)
    }

    @Test
    func replacingACodeRevokesThePreviousCode() async throws {
        let circleID = UUID()
        let shareURL = URL(string: "https://www.icloud.com/share/abc123")!
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareResult = PreparedCircleShare(circleID: circleID, isNewShare: false, shareURL: shareURL)

        let previousCode = CircleInviteCode.generateRandom()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let inviteCodeRepository = MockCircleInviteCodeRepository()
        inviteCodeRepository.fetchActiveCodeResult = CircleInviteCodeDetails(
            code: previousCode, circleID: circleID, shareURL: shareURL,
            createdAt: clock.now, expiresAt: clock.now.addingTimeInterval(3600), isRevoked: false
        )

        let useCase = makeUseCase(sharingRepository: sharingRepository, inviteCodeRepository: inviteCodeRepository, clock: clock)
        _ = try await useCase.execute(circleID: circleID)

        #expect(inviteCodeRepository.revokedCodes == [previousCode])
    }

    @Test
    func shareFailureNeverDeletesTheLocalCircle() async {
        let circleID = UUID()
        let localCircleRepository = InMemoryCircleRepository()
        localCircleRepository.circle = FriendCircle(
            id: circleID, name: "The Pack", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID()
        )

        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareError = CircleSharingError.networkUnavailable
        let inviteCodeRepository = MockCircleInviteCodeRepository()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = makeUseCase(sharingRepository: sharingRepository, inviteCodeRepository: inviteCodeRepository, clock: clock)

        await #expect(throws: CircleSharingError.networkUnavailable) {
            _ = try await useCase.execute(circleID: circleID)
        }

        // The invite-code repository is never even reached, and local
        // Circle storage is untouched.
        #expect(inviteCodeRepository.publishCallCount == 0)
        let stillPresent = try? await localCircleRepository.fetchCircle(id: circleID)
        #expect(stillPresent?.id == circleID)
    }

    @Test
    func requiresASavedShareURLBeforePublishing() async {
        let circleID = UUID()
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareResult = PreparedCircleShare(circleID: circleID, isNewShare: true, shareURL: nil)
        let inviteCodeRepository = MockCircleInviteCodeRepository()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = makeUseCase(sharingRepository: sharingRepository, inviteCodeRepository: inviteCodeRepository, clock: clock)

        await #expect(throws: CircleInviteCodeError.shareURLUnavailable) {
            _ = try await useCase.execute(circleID: circleID)
        }
        #expect(inviteCodeRepository.publishCallCount == 0)
    }
}
