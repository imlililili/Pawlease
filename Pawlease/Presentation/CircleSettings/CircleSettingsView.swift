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

            inviteCodeSection

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

    @ViewBuilder
    private var inviteCodeSection: some View {
        Section("Invite Code") {
            switch viewModel.inviteCodeState {
            case .none:
                Button("Create Invite Code") {
                    Task { await viewModel.createInviteCode() }
                }
                .disabled(viewModel.isCreatingInviteCode)
                .accessibilityHint("Generates a code you can share with a friend to join this Circle.")

            case .loading:
                HStack {
                    ProgressView()
                    Text("Creating invite code…")
                }

            case .active(let display):
                VStack(alignment: .leading, spacing: 8) {
                    Text(display.formattedCode)
                        .font(.title2.monospaced().bold())
                        .accessibilityLabel("Invite code \(display.formattedCode)")
                    Text(display.expiresAtLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if viewModel.didCopyInviteCode {
                        Text("Copied!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                HStack {
                    Button("Copy") {
                        UIPasteboard.general.string = display.formattedCode
                        viewModel.markInviteCodeCopied()
                    }
                    Spacer()
                    ShareLink(item: display.shareURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                    Button("Refresh") {
                        Task { await viewModel.refresh() }
                    }
                }
                .buttonStyle(.borderless)
                Button("Revoke Code", role: .destructive) {
                    Task { await viewModel.revokeInviteCode() }
                }
                .disabled(viewModel.isRevokingInviteCode)

            case .revoked:
                Text("This invite code has been revoked.")
                    .foregroundStyle(.secondary)
                Button("Create New Invite Code") {
                    Task { await viewModel.createInviteCode() }
                }
                .disabled(viewModel.isCreatingInviteCode)

            case .error(let message):
                Text(message)
                    .foregroundStyle(.red)
                Button("Try Again") {
                    Task { await viewModel.createInviteCode() }
                }
                .disabled(viewModel.isCreatingInviteCode)
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
