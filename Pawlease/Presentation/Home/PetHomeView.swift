import SwiftUI

struct PetHomeView: View {
    @State private var viewModel: PetHomeViewModel
    @State private var composerViewModel: PostComposerViewModel?
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: PetHomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Pet Home")
            .task { await viewModel.loadIfNeeded() }
            .task { await viewModel.observeCloudSync() }
            .refreshable { await viewModel.refresh() }
            // Re-checks the shared App Group inbox (via `refresh()`) every
            // time the app becomes active — not just on cold launch — so a
            // photo shared while Pawlease was backgrounded shows up without
            // requiring a manual pull-to-refresh.
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel.refresh() }
                }
            }
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isJoinCirclePresented = true
                    } label: {
                        Label("Join a Circle", systemImage: "person.badge.plus")
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
            .sheet(isPresented: $viewModel.isJoinCirclePresented) {
                JoinCircleView(viewModel: viewModel.makeJoinCircleViewModel())
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

                if let pendingSharedDraft = viewModel.pendingSharedDraft {
                    sharedDraftBanner(for: pendingSharedDraft)
                }

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

                #if DEBUG
                localCollaborationDemoSection
                #endif

                feedSection(state: state)
            }
            .padding()
        }
    }

    private func sharedDraftBanner(for draft: PendingPostDraft) -> some View {
        Button {
            composerViewModel = viewModel.makeComposerViewModel(forPendingDraft: draft)
            viewModel.presentComposer()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shared Photo Ready")
                        .font(.subheadline.bold())
                    Text("Finish reviewing the photo you shared from Photos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Shared photo ready")
        .accessibilityHint("Opens the composer with your shared photo so you can finish posting it.")
    }

    #if DEBUG
    /// Debug-only: simulates a second local Circle member posting, so the
    /// portfolio demo can show 2/2 and a survived day without a second
    /// physical device or CloudKit. Hidden entirely from Release builds —
    /// this whole property only exists in a `#if DEBUG` build.
    private var localCollaborationDemoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Local Demo")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2), in: Capsule())
                    .foregroundStyle(.orange)
                Spacer()
            }

            if viewModel.hasDemoFriendCheckedInToday {
                Label("Ava checked in today", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Button {
                    Task { await viewModel.simulateFriendCheckIn() }
                } label: {
                    if viewModel.demoCheckInState == .checkingIn {
                        HStack {
                            ProgressView()
                            Text("Simulating Ava's Check-in…")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Simulate Ava's Check-in")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canSimulateFriendCheckIn)
                .accessibilityHint("Publishes a local post from a simulated second Circle member, Ava.")

                if case .error(let message) = viewModel.demoCheckInState {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Text("Simulates a second local member because CloudKit provisioning is unavailable in this environment.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    #endif

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
