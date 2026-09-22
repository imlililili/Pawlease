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
}
