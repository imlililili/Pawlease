import Testing
import Foundation
@testable import Pawlease

struct AcceptCircleInvitationUseCaseTests {
    @Test
    func acceptedInvitationRefreshesTheSharedCircle() async throws {
        let sharingRepository = MockCircleSharingRepository()
        let acceptUseCase = AcceptCircleInvitationUseCase(circleSharingRepository: sharingRepository)

        try await acceptUseCase.execute()

        #expect(sharingRepository.acceptPendingInvitationCallCount == 1)

        // After acceptance, refreshing reloads the (now-shared) Circle
        // snapshot — exercised here with in-memory repositories, matching
        // the existing `LoadPetHomeUseCase` test convention.
        let circleID = UUID()
        let memberID = UUID()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))

        let circleRepository = InMemoryCircleRepository()
        circleRepository.circle = FriendCircle(
            id: circleID, name: "Joined Circle", timezoneIdentifier: "UTC", createdAt: clock.now, ownerProfileID: memberID
        )
        let memberRepository = InMemoryMemberRepository()
        memberRepository.members = [TestFactories.member(circleID: circleID, profileID: memberID)]
        let petRepository = InMemoryPetRepository()
        petRepository.pet = SharedPet(
            id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: clock.now
        )
        let momentRepository = InMemoryMomentRepository()

        let loadPetHomeUseCase = LoadPetHomeUseCase(
            circleRepository: circleRepository,
            memberRepository: memberRepository,
            petRepository: petRepository,
            momentRepository: momentRepository,
            clock: clock,
            currentProfileID: memberID
        )
        let refreshUseCase = RefreshSharedCircleUseCase(loadPetHomeUseCase: loadPetHomeUseCase)

        let snapshot = try await refreshUseCase.execute()

        #expect(snapshot.circle.id == circleID)
        #expect(snapshot.circle.name == "Joined Circle")
    }

    @Test
    func acceptanceFailureIsReportedWithoutCrashing() async {
        let sharingRepository = MockCircleSharingRepository()
        sharingRepository.acceptPendingInvitationError = CircleSharingError.invitationAcceptanceFailed(message: "No pending invitation.")
        let useCase = AcceptCircleInvitationUseCase(circleSharingRepository: sharingRepository)

        await #expect(throws: CircleSharingError.self) {
            try await useCase.execute()
        }

        #expect(sharingRepository.acceptPendingInvitationCallCount == 1)
    }
}
