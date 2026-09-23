import Testing
import Foundation
@testable import Pawlease

struct PrepareCircleInvitationUseCaseTests {
    @Test
    func availableICloudAccountAllowsCircleInvitationPreparation() async throws {
        let circleID = UUID()
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .available
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareResult = PreparedCircleShare(circleID: circleID, isNewShare: true)

        let useCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: accountProvider,
            circleSharingRepository: sharingRepository
        )

        let result = try await useCase.execute(circleID: circleID)

        #expect(result.circleID == circleID)
        #expect(result.isNewShare)
        #expect(sharingRepository.prepareShareCapturedCircleIDs == [circleID])
    }

    @Test
    func signedOutICloudAccountPreventsCircleInvitationPreparation() async {
        let circleID = UUID()
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .noAccount
        let sharingRepository = MockCircleSharingRepository()

        let useCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: accountProvider,
            circleSharingRepository: sharingRepository
        )

        await #expect(throws: CircleSharingError.iCloudAccountUnavailable(.noAccount)) {
            _ = try await useCase.execute(circleID: circleID)
        }

        // The repository is never even reached once the account check fails.
        #expect(sharingRepository.prepareShareCallCount == 0)
    }

    @Test
    func existingCircleShareIsReusedInsteadOfDuplicated() async throws {
        let circleID = UUID()
        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .available
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareResult = PreparedCircleShare(circleID: circleID, isNewShare: false)

        let useCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: accountProvider,
            circleSharingRepository: sharingRepository
        )

        let result = try await useCase.execute(circleID: circleID)

        #expect(result.isNewShare == false)
        #expect(sharingRepository.prepareShareCallCount == 1)
    }

    @Test
    func invitationFailureIsPresentedWithoutRemovingLocalCircleData() async throws {
        let circleID = UUID()
        let localCircleRepository = InMemoryCircleRepository()
        localCircleRepository.circle = FriendCircle(
            id: circleID, name: "The Pack", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID()
        )

        let accountProvider = MockCloudAccountStatusProvider()
        accountProvider.stubbedStatus = .available
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.prepareShareError = CircleSharingError.networkUnavailable

        let useCase = PrepareCircleInvitationUseCase(
            cloudAccountStatusProvider: accountProvider,
            circleSharingRepository: sharingRepository
        )

        await #expect(throws: CircleSharingError.networkUnavailable) {
            _ = try await useCase.execute(circleID: circleID)
        }

        // The failed sharing attempt never touches local Circle storage.
        let stillPresent = try await localCircleRepository.fetchDefaultCircle()
        #expect(stillPresent?.id == circleID)
        #expect(stillPresent?.name == "The Pack")
    }
}
