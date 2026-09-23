import SwiftUI

struct PetHomeView: View {
    @State private var viewModel: PetHomeViewModel
    @State private var composerViewModel: PostComposerViewModel?

    init(viewModel: PetHomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Pet Home")
            .task { await viewModel.loadIfNeeded() }
            .task { await viewModel.observeCloudSync() }
            .refreshable { await viewModel.refresh() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        CircleSettingsView(
                            viewModel: viewModel.makeCircleSettingsViewModel(),
                            cloudSharingControllerProvider: viewModel.cloudSharingControllerProvider
                        )
                    } label: {
                        Label("Circle Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isComposerPresented, onDismiss: handleComposerDismiss) {
                if let composerViewModel {
                    NavigationStack {
                        PostComposerView(viewModel: composerViewModel)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { momentID in
                if let postDetailViewModel = viewModel.makePostDetailViewModel(momentID: momentID) {
                    PostDetailView(viewModel: postDetailViewModel)
                }
            }
    }

    private func handleComposerDismiss() {
        let didPublish = composerViewModel?.didPublish ?? false
        composerViewModel = nil
        Task { await viewModel.handleComposerDismissed(didPublish: didPublish) }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading your Circle…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.refresh() } }
            }
        case .loaded:
            if let state = viewModel.viewState {
                loadedContent(state: state)
            }
        }
    }

    private func loadedContent(state: PetHomeViewState) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                PetStateCard(state: state)
                ContributorProgressCard(state: state)
                SyncStatusBadge(status: viewModel.syncStatus)

                Button {
                    composerViewModel = viewModel.makeComposerViewModel()
                    viewModel.presentComposer()
                } label: {
                    Label("Take Today's Photo", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Opens the photo picker so you can share today's moment.")

                feedSection(state: state)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func feedSection(state: PetHomeViewState) -> some View {
        if !state.canViewFeed {
            ContentUnavailableView {
                Label("Feed Locked", systemImage: "lock.fill")
            } description: {
                Text("Share today's moment to see what your friends posted.")
            }
        } else if let feedError = viewModel.feedError {
            ContentUnavailableView {
                Label("Couldn't Load Feed", systemImage: "wifi.slash")
            } description: {
                Text(feedError)
            }
        } else if viewModel.todayMoments.isEmpty {
            ContentUnavailableView {
                Label("No Moments Yet", systemImage: "photo.on.rectangle")
            } description: {
                Text("You're the first one today. Check back soon!")
            }
        } else {
            TodayFeedView(moments: viewModel.todayMoments)
        }
    }
}
