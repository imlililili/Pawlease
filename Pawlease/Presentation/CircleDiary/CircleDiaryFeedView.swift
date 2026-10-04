import SwiftUI

struct CircleDiaryFeedView: View {
    @State private var viewModel: CircleDiaryFeedViewModel
    @State private var composerViewModel: DiaryComposerViewModel?

    init(viewModel: CircleDiaryFeedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .background(PawleaseTheme.background)
            .navigationTitle("Circle Diary")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
            .task { await viewModel.privacyMonitor.startObserving() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isArchivePresented = true
                    } label: {
                        Image(systemName: "archivebox")
                    }
                    .accessibilityLabel("My Archive")
                }
            }
            .safeAreaInset(edge: .bottom) {
                newDiaryEntryButton
            }
            .sheet(isPresented: $viewModel.isComposerPresented, onDismiss: handleComposerDismiss) {
                if let composerViewModel {
                    DiaryComposerView(viewModel: composerViewModel)
                }
            }
            .sheet(isPresented: $viewModel.isArchivePresented) {
                NavigationStack {
                    DiaryArchiveView(viewModel: viewModel.makeArchiveViewModel())
                }
            }
            .navigationDestination(for: DiaryEntryRoute.self) { route in
                DiaryEntryDetailView(viewModel: viewModel.makeDetailViewModel(entryID: route.entryID))
            }
            .overlay(alignment: .top) {
                if let message = viewModel.privacyMonitor.screenshotWarningMessage {
                    screenshotWarningBanner(message: message)
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
            ProgressView("Loading Circle Diary…")
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
            VStack(spacing: 0) {
                introText
                if viewModel.viewState.entries.isEmpty {
                    ContentUnavailableView {
                        Label("No Diary Entries Yet", systemImage: "text.bubble")
                    } description: {
                        Text("Share the first thought with your Circle.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    feedList
                }
            }
        }
    }

    private var introText: some View {
        Text("A private text feed for the people who share \(viewModel.petName).")
            .font(.subheadline)
            .foregroundStyle(PawleaseTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PawleaseTheme.pagePadding)
            .padding(.vertical, 14)
    }

    private var feedList: some View {
        List {
            ForEach(viewModel.viewState.entries) { item in
                NavigationLink(value: DiaryEntryRoute(entryID: item.id)) {
                    DiaryEntryRow(
                        item: item,
                        isOwnEntry: item.authorProfileID == viewModel.currentMember.profileID,
                        onDelete: { Task { await viewModel.deleteEntry(entryID: item.id) } },
                        privacyMonitor: viewModel.privacyMonitor
                    )
                }
                .listRowBackground(PawleaseTheme.background)
                .listRowSeparatorTint(PawleaseTheme.divider)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    private var newDiaryEntryButton: some View {
        Button {
            composerViewModel = viewModel.makeComposerViewModel()
            viewModel.presentComposer()
        } label: {
            Label("New Diary Entry", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PawleasePrimaryButtonStyle())
        .padding(.horizontal, PawleaseTheme.pagePadding)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(.bar)
    }

    private func screenshotWarningBanner(message: String) -> some View {
        Text(message)
            .font(.caption)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.yellow.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
            .padding()
            .onTapGesture { viewModel.privacyMonitor.dismissScreenshotWarning() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(message)
            .accessibilityHint("Double tap to dismiss")
    }
}
