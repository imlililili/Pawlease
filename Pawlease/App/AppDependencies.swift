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
    let commentRepository: CommentRepository
    let momentReactionRepository: MomentReactionRepository
    let commentReactionRepository: CommentReactionRepository

    let photoProcessingService: PhotoProcessingService

    let seedDemoCircleUseCase: SeedDemoCircleUseCase
    let loadPetHomeUseCase: LoadPetHomeUseCase
    let loadTodayMomentsUseCase: LoadTodayMomentsUseCase
    let publishDailyMomentUseCase: PublishDailyMomentUseCase
    let loadMomentDetailUseCase: LoadMomentDetailUseCase
    let addCommentUseCase: AddCommentUseCase
    let removeCommentUseCase: RemoveCommentUseCase
    let reactToMomentUseCase: ReactToMomentUseCase
    let reactToCommentUseCase: ReactToCommentUseCase

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
        let commentRepo = CoreDataCommentRepository(container: container)
        let momentReactionRepo = CoreDataMomentReactionRepository(container: container)
        let commentReactionRepo = CoreDataCommentReactionRepository(container: container)

        self.circleRepository = circleRepo
        self.memberRepository = memberRepo
        self.petRepository = petRepo
        self.momentRepository = momentRepo
        self.commentRepository = commentRepo
        self.momentReactionRepository = momentReactionRepo
        self.commentReactionRepository = commentReactionRepo

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
        self.loadMomentDetailUseCase = LoadMomentDetailUseCase(
            momentRepository: momentRepo,
            commentRepository: commentRepo,
            momentReactionRepository: momentReactionRepo,
            commentReactionRepository: commentReactionRepo
        )
        self.addCommentUseCase = AddCommentUseCase(
            commentRepository: commentRepo,
            momentRepository: momentRepo,
            clock: clock
        )
        self.removeCommentUseCase = RemoveCommentUseCase(commentRepository: commentRepo)
        self.reactToMomentUseCase = ReactToMomentUseCase(
            momentReactionRepository: momentReactionRepo,
            clock: clock
        )
        self.reactToCommentUseCase = ReactToCommentUseCase(
            commentReactionRepository: commentReactionRepo,
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
