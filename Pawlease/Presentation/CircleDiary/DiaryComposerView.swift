import SwiftUI

struct DiaryComposerView: View {
    @State private var viewModel: DiaryComposerViewModel
    @State private var isDismissConfirmationPresented = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DiaryComposerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $viewModel.bodyText)
                        .frame(minHeight: 160)
                        .accessibilityLabel("Diary entry text")
                    HStack {
                        Spacer()
                        Text(viewModel.characterCountLabel)
                            .font(.caption)
                            .foregroundStyle(viewModel.isBodyValid || viewModel.bodyText.isEmpty ? Color.secondary : Color.red)
                            .accessibilityLabel("\(viewModel.characterCountLabel) characters used")
                    }
                }

                Section("Visible For") {
                    Picker("Visible For", selection: $viewModel.visibilityDuration) {
                        ForEach(DiaryVisibilityDuration.allCases, id: \.self) { duration in
                            Text(duration.displayName).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                if case .error(let message) = viewModel.publishState {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Diary Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { attemptDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.publish()
                            if viewModel.didPublish { dismiss() }
                        }
                    } label: {
                        if viewModel.publishState == .publishing {
                            ProgressView()
                        } else {
                            Text("Publish")
                        }
                    }
                    .disabled(!viewModel.canPublish)
                    .accessibilityHint(viewModel.canPublish ? "" : "Write something to publish")
                }
            }
            .confirmationDialog(
                "Discard this entry?",
                isPresented: $isDismissConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
        }
    }

    private func attemptDismiss() {
        if viewModel.hasUnsavedContent {
            isDismissConfirmationPresented = true
        } else {
            dismiss()
        }
    }
}
