import SwiftUI

struct DiaryEntryDetailView: View {
    @State private var viewModel: DiaryEntryDetailViewModel
    @State private var isDeleteConfirmationPresented = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DiaryEntryDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Diary Entry")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
            .task { await viewModel.privacyMonitor.startObserving() }
            .onChange(of: viewModel.didDeleteEntry) { _, didDelete in
                if didDelete { dismiss() }
            }
            .confirmationDialog(
                "Delete this entry?",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { Task { await viewModel.deleteEntry() } }
                Button("Cancel", role: .cancel) {}
            }
            .overlay(alignment: .top) {
                if let message = viewModel.privacyMonitor.screenshotWarningMessage {
                    Text(message)
                        .font(.caption)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(.yellow.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                        .padding()
                        .onTapGesture { viewModel.privacyMonitor.dismissScreenshotWarning() }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading entry…")
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

    private func loadedContent(state: DiaryEntryDetailViewState) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    entryInfo(state: state)

                    if isShielded(state) {
                        PrivacyShieldView()
                    } else {
                        Text(state.bodyText)
                            .font(.body)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        DiaryReactionButton(
                            currentReactionEmoji: state.currentMemberEntryReactionEmoji,
                            onSubmit: { emoji in Task { await viewModel.reactToEntry(withRawEmoji: emoji) } },
                            onRemove: { Task { await viewModel.reactToEntry(withRawEmoji: state.currentMemberEntryReactionEmoji ?? "") } }
                        )
                        DiaryReactionSummaryView(items: state.entryReactionSummary)
                    }

                    if state.isOwnEntry {
                        Button(role: .destructive) {
                            isDeleteConfirmationPresented = true
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete your Diary entry")
                    }

                    if let actionErrorMessage = viewModel.actionErrorMessage {
                        Text(actionErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Divider()

                    commentsSection(state: state)
                }
                .padding()
            }
            .refreshable { await viewModel.refresh() }

            Divider()

            CommentComposer(
                text: $viewModel.commentText,
                characterLimit: viewModel.characterLimit,
                isValid: viewModel.isCommentValid,
                isSubmitting: viewModel.isSubmittingComment,
                errorMessage: viewModel.commentErrorMessage,
                onSubmit: { Task { await viewModel.submitComment() } }
            )
            .padding()
        }
    }

    private func isShielded(_ state: DiaryEntryDetailViewState) -> Bool {
        !state.isPermanent && viewModel.privacyMonitor.shouldShieldTimedContent
    }

    private func entryInfo(state: DiaryEntryDetailViewState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(state.authorAvatarEmoji)
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.authorName)
                        .font(.headline)
                    Text(state.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let expirationLabel = state.expirationLabel {
                    Text(expirationLabel)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func commentsSection(state: DiaryEntryDetailViewState) -> some View {
        Text("Comments")
            .font(.headline)

        if state.comments.isEmpty {
            ContentUnavailableView {
                Label("No Comments Yet", systemImage: "bubble.left")
            } description: {
                Text("Be the first to say something.")
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(state.comments) { comment in
                    DiaryCommentRow(
                        comment: comment,
                        onReact: { emoji in Task { await viewModel.reactToComment(commentID: comment.id, withRawEmoji: emoji) } },
                        onRemoveReaction: {
                            Task { await viewModel.reactToComment(commentID: comment.id, withRawEmoji: comment.currentMemberReactionEmoji ?? "") }
                        }
                    )
                    Divider()
                }
            }
        }
    }
}
