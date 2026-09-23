import Testing
import Foundation
@testable import Pawlease

struct SeedDemoCircleUseCaseTests {
    @Test func seedsOneCircleWithThreeMembersAndOnePetIdempotently() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let container = persistence.container
        let useCase = SeedDemoCircleUseCase(
            circleRepository: CoreDataCircleRepository(container: container),
            memberRepository: CoreDataMemberRepository(container: container),
            petRepository: CoreDataPetRepository(container: container),
            clock: SystemClock()
        )

        let result = try await useCase.execute()
        let resultAgain = try await useCase.execute()

        #expect(result.members.count == 3)
        #expect(resultAgain.circle.id == result.circle.id)
        #expect(resultAgain.members.count == 3)
    }

    /// Regression test for the Circle Settings duplicate-member bug:
    /// `.task { loadIfNeeded() }`, `.onChange(of: scenePhase)`, and a
    /// remote-change pulse could all call `PetHomeViewModel.refresh()` —
    /// and therefore `SeedDemoCircleUseCase.execute()` — around the same
    /// moment at launch, before `PetHomeViewModel` coalesced concurrent
    /// refreshes. Firing many genuinely concurrent `execute()` calls here
    /// reproduces that race directly against the real Core Data stack and
    /// proves the repository-level fix holds even without the ViewModel's
    /// own coalescing guard.
    @Test func concurrentSeedAttemptsNeverCreateDuplicateMembers() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let container = persistence.container
        let useCase = SeedDemoCircleUseCase(
            circleRepository: CoreDataCircleRepository(container: container),
            memberRepository: CoreDataMemberRepository(container: container),
            petRepository: CoreDataPetRepository(container: container),
            clock: SystemClock()
        )

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask { _ = try? await useCase.execute() }
            }
        }

        let memberRepo = CoreDataMemberRepository(container: container)
        let members = try await memberRepo.fetchMembers(circleID: DemoSeed.circleID)
        #expect(members.count == 3)
        #expect(Set(members.map(\.profileID)) == Set(DemoSeed.memberProfileIDs))
    }
}
