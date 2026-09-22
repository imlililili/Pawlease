import SwiftUI

struct PostDetailView: View {
    @State private var viewModel: PostDetailViewModel

    init(viewModel: PostDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Moment")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading moment…")
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

    private func loadedContent(state: PostDetailViewState) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photo(state: state)
                    momentInfo(state: state)

                    VStack(alignment: .leading, spacing: 6) {
                        ReactionPicker(selectedEmoji: state.currentMemberMomentReaction) { emoji in
                            Task { await viewModel.reactToMoment(with: emoji) }
                        }
                        ReactionSummary(items: state.momentReactionSummary)
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

    private func momentInfo(state: PostDetailViewState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(state.authorName)
                    .font(.headline)
                if let mood = state.moodEmoji {
                    Text(mood)
                }
                Spacer()
                Text(state.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(state.caption)
                .font(.body)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func commentsSection(state: PostDetailViewState) -> some View {
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
                    CommentRow(
                        comment: comment,
                        onReact: { emoji in Task { await viewModel.reactToComment(commentID: comment.id, with: emoji) } },
                        onDelete: { Task { await viewModel.removeComment(commentID: comment.id) } }
                    )
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func photo(state: PostDetailViewState) -> some View {
        if let uiImage = UIImage(data: state.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)
        } else {
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
