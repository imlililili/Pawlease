import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            PetHomeView(
                viewModel: PetHomeViewModel(
                    loadPetHomeUseCase: dependencies.loadPetHomeUseCase,
                    loadTodayMomentsUseCase: dependencies.loadTodayMomentsUseCase,
                    seedDemoCircleUseCase: dependencies.seedDemoCircleUseCase,
                    publishDailyMomentUseCase: dependencies.publishDailyMomentUseCase,
                    photoProcessingService: dependencies.photoProcessingService
                )
            )
        }
    }
}
