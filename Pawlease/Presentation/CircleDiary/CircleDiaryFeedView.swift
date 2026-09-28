import SwiftUI

struct CircleDiaryFeedView: View {
    @State private var viewModel: CircleDiaryFeedViewModel
    @State private var composerViewModel: DiaryComposerViewModel?

    init(viewModel: CircleDiaryFeedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Circle Diary")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
            .task { await viewModel.privacyMonitor.startObserving() }
            .refreshable { await viewModel.refresh() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        composerViewModel = viewModel.makeComposerViewModel()
                        viewModel.presentComposer()
                    } label: {
                        Label("New Diary Entry", systemImage: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        viewModel.isArchivePresented = true
                    } label: {
                        Label("My Archive", systemImage: "archivebox")
                    }
                }
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
            if viewModel.viewState.entries.isEmpty {
                ContentUnavailableView {
                    Label("No Diary Entries Yet", systemImage: "text.bubble")
                } description: {
                    Text("Share the first thought with your Circle.")
                } actions: {
                    Button("New Diary Entry") {
                        composerViewModel = viewModel.makeComposerViewModel()
                        viewModel.presentComposer()
                    }
                }
            } else {
                feedList
            }
        }
    }

    private var feedList: some View {
        List {
            ForEach(viewModel.viewState.entries) { item in
                NavigationLink(value: DiaryEntryRoute(entryID: item.id)) {
                    DiaryEntryRow(item: item, isShielded: viewModel.privacyMonitor.shouldShieldTimedContent)
                }
            }
        }
        .listStyle(.plain)
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
