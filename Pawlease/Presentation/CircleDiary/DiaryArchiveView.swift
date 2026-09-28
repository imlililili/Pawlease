import SwiftUI

/// "My Diary Archive": the current member's own expired timed entries.
/// Read-only except that the author can still delete an archived entry —
/// enforced by reusing the same `DiaryEntryDetailView`/ViewModel the shared
/// feed uses, so there is no second, divergent detail implementation.
struct DiaryArchiveView: View {
    @State private var viewModel: DiaryArchiveViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DiaryArchiveViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("My Diary Archive")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
            .refreshable { await viewModel.refresh() }
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
            if viewModel.entries.isEmpty {
                ContentUnavailableView {
                    Label("Nothing Archived Yet", systemImage: "archivebox")
                } description: {
                    Text("Timed Diary entries move here once they expire from the shared feed.")
                }
            } else {
                List(viewModel.entries) { entry in
                    NavigationLink(value: DiaryEntryRoute(entryID: entry.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.body.value)
                                .lineLimit(3)
                            Text(entry.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
