import SwiftUI

struct ShareComposeView: View {
    @State private var viewModel: ShareComposeViewModel
    let onFinish: () -> Void
    let onCancel: () -> Void

    init(viewModel: ShareComposeViewModel, onFinish: @escaping () -> Void, onCancel: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Share to Pawlease")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Task {
                                let didSave = await viewModel.save()
                                if didSave { onFinish() }
                            }
                        } label: {
                            if viewModel.saveState == .saving {
                                ProgressView()
                            } else {
                                Text("Save")
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView("Loading photo…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            ContentUnavailableView {
                Label("Couldn't Load Photo", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            }
        case .ready:
            readyContent
        }
    }

    private var readyContent: some View {
        Form {
            Section {
                if let previewImage = viewModel.previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Selected photo")
                }
            }

            Section {
                TextField("Add a caption (optional)", text: $viewModel.captionText, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityLabel("Caption")
                HStack {
                    Spacer()
                    Text(viewModel.characterCountLabel)
                        .font(.caption)
                        .foregroundStyle(viewModel.isCaptionValid ? Color.secondary : Color.red)
                        .accessibilityLabel("\(viewModel.characterCountLabel) characters used")
                }
            } header: {
                Text("Caption")
            }

            if case .error(let message) = viewModel.saveState {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }

            if viewModel.saveState == .success {
                Section {
                    Label("Saved to Pawlease", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }
}
