import SwiftUI

/// "My Archive": the current member's own expired timed entries. Read-only
/// except that the author can still delete an archived entry — enforced by
/// reusing the same `DiaryEntryDetailView`/ViewModel the shared feed uses,
/// so there is no second, divergent detail implementation.
struct DiaryArchiveView: View {
    @State private var viewModel: DiaryArchiveViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DiaryArchiveViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .background(PawleaseTheme.background)
            .navigationTitle("My Archive")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: DiaryEntryRoute.self) { route in
                DiaryEntryDetailView(viewModel: viewModel.makeDetailViewModel(entryID: route.entryID))
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading your Archive…")
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
                if viewModel.entries.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing Archived Yet", systemImage: "archivebox")
                    } description: {
                        Text("Timed Diary entries move here once they expire from the shared feed.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.entries) { item in
                        NavigationLink(value: DiaryEntryRoute(entryID: item.id)) {
                            DiaryArchiveEntryRow(item: item)
                        }
                        .listRowBackground(PawleaseTheme.background)
                        .listRowSeparatorTint(PawleaseTheme.divider)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.refresh() }
                }
            }
        }
    }

    private var introText: some View {
        Text("Your expired entries stay here with their comments and reactions.")
            .font(.subheadline)
            .foregroundStyle(PawleaseTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PawleaseTheme.pagePadding)
            .padding(.vertical, 14)
    }
}
