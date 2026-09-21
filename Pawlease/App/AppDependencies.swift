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

    let photoProcessingService: PhotoProcessingService

    let seedDemoCircleUseCase: SeedDemoCircleUseCase
    let loadPetHomeUseCase: LoadPetHomeUseCase
    let loadTodayMomentsUseCase: LoadTodayMomentsUseCase
    let publishDailyMomentUseCase: PublishDailyMomentUseCase

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

        self.circleRepository = circleRepo
        self.memberRepository = memberRepo
        self.petRepository = petRepo
        self.momentRepository = momentRepo

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
    }

    static func live() -> AppDependencies {
        AppDependencies(persistenceController: .shared)
    }

    static func preview() -> AppDependencies {
        AppDependencies(persistenceController: .preview)
    }
}
