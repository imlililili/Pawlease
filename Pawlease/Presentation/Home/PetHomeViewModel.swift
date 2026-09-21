import Foundation
import Observation

/// Coordinates the Pet Home workflow: loading the seeded Circle snapshot,
/// unlocking/loading today's feed, and presenting the Post Composer. Holds
/// no business rules itself — everything is delegated to Use Cases.
@MainActor
@Observable
final class PetHomeViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var snapshot: PetHomeSnapshot?
    private(set) var todayMoments: [DailyMoment] = []
    private(set) var feedError: String?
    var isComposerPresented = false

    var viewState: PetHomeViewState? {
        snapshot.map(PetHomeViewState.init)
    }

    private let loadPetHomeUseCase: LoadPetHomeUseCase
    private let loadTodayMomentsUseCase: LoadTodayMomentsUseCase
    private let seedDemoCircleUseCase: SeedDemoCircleUseCase
    private let publishDailyMomentUseCase: PublishDailyMomentUseCase
    private let photoProcessingService: PhotoProcessingService

    init(
        loadPetHomeUseCase: LoadPetHomeUseCase,
        loadTodayMomentsUseCase: LoadTodayMomentsUseCase,
        seedDemoCircleUseCase: SeedDemoCircleUseCase,
        publishDailyMomentUseCase: PublishDailyMomentUseCase,
        photoProcessingService: PhotoProcessingService
    ) {
        self.loadPetHomeUseCase = loadPetHomeUseCase
        self.loadTodayMomentsUseCase = loadTodayMomentsUseCase
        self.seedDemoCircleUseCase = seedDemoCircleUseCase
        self.publishDailyMomentUseCase = publishDailyMomentUseCase
        self.photoProcessingService = photoProcessingService
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await refresh()
    }

    func refresh() async {
        loadState = .loading
        do {
            _ = try await seedDemoCircleUseCase.execute()
            let snapshot = try await loadPetHomeUseCase.execute()
            self.snapshot = snapshot

            if snapshot.canViewTodayFeed {
                do {
                    todayMoments = try await loadTodayMomentsUseCase.execute(
                        circleID: snapshot.circle.id,
                        requestingProfileID: snapshot.currentMember.profileID,
                        day: snapshot.today
                    )
                    feedError = nil
                } catch {
                    todayMoments = []
                    feedError = "Couldn't load your friends' moments. Pull to refresh to try again."
                }
            } else {
                todayMoments = []
                feedError = nil
            }

            loadState = .loaded
        } catch {
            loadState = .error(Self.message(for: error))
        }
    }

    func presentComposer() {
        isComposerPresented = true
    }

    func handleComposerDismissed(didPublish: Bool) async {
        isComposerPresented = false
        if didPublish {
            await refresh()
        }
    }

    func makeComposerViewModel() -> PostComposerViewModel? {
        guard let snapshot else { return nil }
        return PostComposerViewModel(
            circle: snapshot.circle,
            member: snapshot.currentMember,
            publishDailyMomentUseCase: publishDailyMomentUseCase,
            photoProcessingService: photoProcessingService
        )
    }

    private static func message(for error: Error) -> String {
        if let domainError = error as? DomainError {
            switch domainError {
            case .circleNotFound: return "We couldn't find your Circle."
            case .memberNotFound: return "We couldn't find your profile in this Circle."
            case .petNotFound: return "Your pet is missing. Please try again."
            case .feedLocked: return "Post today's moment to unlock your friends' feed."
            }
        }
        return "Something went wrong. Please try again."
    }
}
