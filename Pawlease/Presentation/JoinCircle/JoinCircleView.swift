import SwiftUI

struct JoinCircleView: View {
    @State private var viewModel: JoinCircleViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: JoinCircleViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("PAW-XXXX-XXXX", text: $viewModel.codeInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Invite code")
                } header: {
                    Text("Invite Code")
                } footer: {
                    Text("Ask a Circle owner for their invite code, then enter it here to join.")
                }

                statusSection

                Section {
                    Button("Join Circle") {
                        Task { await viewModel.joinCircle() }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .navigationTitle("Join a Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.resolveState {
        case .idle:
            EmptyView()
        case .resolving:
            Section {
                HStack { ProgressView(); Text("Checking code…") }
            }
        case .opening:
            Section {
                HStack { ProgressView(); Text("Opening your Circle invitation…") }
            }
        case .error(let message):
            Section {
                Text(message).foregroundStyle(.red)
            }
        }
    }
}
