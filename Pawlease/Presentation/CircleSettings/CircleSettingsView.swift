import SwiftUI
import UIKit

struct CircleSettingsView: View {
    @State private var viewModel: CircleSettingsViewModel
    private let cloudSharingControllerProvider: CloudSharingControllerProviding

    @State private var sharingController: UICloudSharingController?
    @State private var isPresentingSharingController = false
    @State private var sharingPreparationError: String?

    init(viewModel: CircleSettingsViewModel, cloudSharingControllerProvider: CloudSharingControllerProviding) {
        _viewModel = State(initialValue: viewModel)
        self.cloudSharingControllerProvider = cloudSharingControllerProvider
    }

    var body: some View {
        content
            .navigationTitle("Circle Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
            .refreshable { await viewModel.refresh() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh Circle Settings")
                }
            }
            .onChange(of: viewModel.preparedCircleID) { _, newValue in
                guard let circleID = newValue else { return }
                Task { await presentSharingController(circleID: circleID) }
            }
            .sheet(isPresented: $isPresentingSharingController, onDismiss: {
                sharingController = nil
                Task { await viewModel.handleSharingSheetDismissed() }
            }) {
                if let sharingController {
                    CloudSharingControllerRepresentable(controller: sharingController)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading Circle Settings…")
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

    private func loadedContent(state: CircleSettingsViewState) -> some View {
        Form {
            Section("Circle") {
                LabeledContent("Name", value: state.circleName)
                LabeledContent("Pet", value: state.petName)
            }

            Section {
                CircleMembersList(memberNames: state.memberNames)
            }

            Section("iCloud") {
                LabeledContent("Account", value: state.accountStatusLabel)
                LabeledContent("Sharing", value: state.sharingStateLabel)
                if let lastUpdatedLabel = state.lastUpdatedLabel {
                    Text(lastUpdatedLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let actionErrorMessage = viewModel.actionErrorMessage {
                Section {
                    Text(actionErrorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { await viewModel.prepareInvitation() }
                } label: {
                    if viewModel.isPreparingInvitation {
                        HStack {
                            ProgressView()
                            Text(state.inviteButtonLabel)
                        }
                    } else {
                        Text(state.inviteButtonLabel)
                    }
                }
                .disabled(!state.canInvite || viewModel.isPreparingInvitation)
                .accessibilityHint(
                    state.canInvite
                        ? "Opens the invitation sheet to add friends to your Circle."
                        : "Sign in to iCloud to invite friends."
                )
            }
        }
    }

    @MainActor
    private func presentSharingController(circleID: UUID) async {
        do {
            let controller = try await cloudSharingControllerProvider.makeSharingController(circleID: circleID) { outcome in
                Task { @MainActor in await viewModel.handleSharingOutcome(outcome) }
            }
            sharingController = controller
            isPresentingSharingController = true
        } catch let error as CircleSharingError {
            await viewModel.handleSharingOutcome(.failed(error))
        } catch {
            await viewModel.handleSharingOutcome(.failed(.unknown(message: error.localizedDescription)))
        }
        viewModel.handleSharingControllerRequestCompleted()
    }
}
