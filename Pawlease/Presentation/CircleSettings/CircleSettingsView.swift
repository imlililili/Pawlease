import SwiftUI
import UIKit

struct CircleSettingsView: View {
    @State private var viewModel: CircleSettingsViewModel
    private let cloudSharingControllerProvider: CloudSharingControllerProviding
    private let makeJoinCircleViewModel: () -> JoinCircleViewModel

    @State private var sharingController: UICloudSharingController?
    @State private var isPresentingSharingController = false
    @State private var sharingPreparationError: String?
    /// Join a Circle's own entry point now lives here rather than as a
    /// second, redundant invite control on Pet Home's toolbar — the
    /// invite-code and CKShare invite flows just above already cover
    /// *inviting* friends; this is the complementary *joining* flow.
    @State private var isJoinCirclePresented = false

    init(
        viewModel: CircleSettingsViewModel,
        cloudSharingControllerProvider: CloudSharingControllerProviding,
        makeJoinCircleViewModel: @escaping () -> JoinCircleViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.cloudSharingControllerProvider = cloudSharingControllerProvider
        self.makeJoinCircleViewModel = makeJoinCircleViewModel
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
            .sheet(isPresented: $isJoinCirclePresented) {
                JoinCircleView(viewModel: makeJoinCircleViewModel())
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading Circle Settings…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PawleaseTheme.background)
        case .error(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.refresh() } }
            }
            .background(PawleaseTheme.background)
        case .loaded:
            if let state = viewModel.viewState {
                loadedContent(state: state)
            }
        }
    }

    private func loadedContent(state: CircleSettingsViewState) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PawleaseTheme.sectionSpacing) {
                section(header: "CIRCLE") {
                    settingsRow("Circle name", value: state.circleName)
                    rowDivider
                    settingsRow("Pet name", value: state.petName)
                    rowDivider
                    settingsRow("Circle time zone", value: state.timeZoneLabel)
                }

                section(header: state.memberCountLabel) {
                    CircleMembersList(members: state.members)
                }

                section(header: "INVITE CODE") {
                    Text("Friends can enter this code in Pawlease to join your private Circle.")
                        .font(.subheadline)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                    rowDivider
                    inviteCodeSection
                }

                section(header: "ICLOUD AND SHARING") {
                    settingsRow("Account", value: state.accountStatusLabel)
                    rowDivider
                    settingsRow("Sharing", value: state.sharingStateLabel)
                    if let lastUpdatedLabel = state.lastUpdatedLabel {
                        Text(lastUpdatedLabel)
                            .font(.caption)
                            .foregroundStyle(PawleaseTheme.textSecondary)
                    }

                    if let actionErrorMessage = viewModel.actionErrorMessage {
                        Text(actionErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await viewModel.prepareInvitation() }
                    } label: {
                        HStack {
                            if viewModel.isPreparingInvitation {
                                ProgressView()
                            }
                            Text(state.inviteButtonLabel)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PawleaseSecondaryButtonStyle())
                    .disabled(!state.canInvite || viewModel.isPreparingInvitation)
                    .accessibilityHint(
                        state.canInvite
                            ? "Opens the invitation sheet to add friends to your Circle."
                            : "Sign in to iCloud to invite friends."
                    )
                    .padding(.top, 4)

                    Text("Uses Apple's native CloudKit sharing sheet — separate from the invite code above. On a Personal Team development build, iCloud sharing may be unavailable; the invite code and the local collaboration demo still work without it.")
                        .font(.caption)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                }

                section(header: "ANOTHER CIRCLE") {
                    Text("Have an invite code from a friend? Join their Circle instead.")
                        .font(.subheadline)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                    Button {
                        isJoinCirclePresented = true
                    } label: {
                        Label("Join a Circle", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PawleaseSecondaryButtonStyle())
                    .accessibilityHint("Opens a form to enter a friend's invite code and join their Circle.")
                }
            }
            .padding(PawleaseTheme.pagePadding)
        }
        .background(PawleaseTheme.background)
    }

    // MARK: - Shared row building blocks

    private func section<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(.caption.weight(.semibold))
                .tracking(0.4)
                .foregroundStyle(PawleaseTheme.textSecondary)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
        }
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(PawleaseTheme.textPrimary)
            Spacer()
            Text(value)
                .foregroundStyle(PawleaseTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(PawleaseTheme.divider)
            .frame(height: 1)
    }

    @ViewBuilder
    private var inviteCodeSection: some View {
        switch viewModel.inviteCodeState {
        case .none:
            Button {
                Task { await viewModel.createInviteCode() }
            } label: {
                Label("Create Invite Code", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PawleasePrimaryButtonStyle())
            .disabled(viewModel.isCreatingInviteCode)
            .accessibilityHint("Generates a code you can share with a friend to join this Circle.")

        case .loading:
            HStack {
                ProgressView()
                Text("Creating invite code…")
                    .foregroundStyle(PawleaseTheme.textSecondary)
            }

        case .active(let display):
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(display.formattedCode)
                        .font(.title2.monospaced().bold())
                        .foregroundStyle(PawleaseTheme.textPrimary)
                        .accessibilityLabel("Invite code \(display.formattedCode)")
                    Spacer()
                    Button {
                        UIPasteboard.general.string = display.formattedCode
                        viewModel.markInviteCodeCopied()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(PawleaseTheme.divider, lineWidth: 1)
                    )
                    .accessibilityLabel("Copy invite code")
                }

                Text(display.expiresAtLabel)
                    .font(.footnote)
                    .foregroundStyle(PawleaseTheme.textSecondary)

                if viewModel.didCopyInviteCode {
                    Text("Copied!")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }

                HStack(spacing: 12) {
                    ShareLink(item: display.shareURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PawleaseSecondaryButtonStyle())

                    Button {
                        Task { await viewModel.createInviteCode() }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PawleaseSecondaryButtonStyle())
                    .disabled(viewModel.isCreatingInviteCode)
                }

                Button("Revoke Code", role: .destructive) {
                    Task { await viewModel.revokeInviteCode() }
                }
                .disabled(viewModel.isRevokingInviteCode)
                .frame(maxWidth: .infinity, minHeight: 44)
            }

        case .revoked:
            VStack(alignment: .leading, spacing: 10) {
                Text("This invite code has been revoked.")
                    .foregroundStyle(PawleaseTheme.textSecondary)
                Button {
                    Task { await viewModel.createInviteCode() }
                } label: {
                    Text("Create New Invite Code")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PawleasePrimaryButtonStyle())
                .disabled(viewModel.isCreatingInviteCode)
            }

        case .error(let message):
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .foregroundStyle(.red)
                Button {
                    Task { await viewModel.createInviteCode() }
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PawleaseSecondaryButtonStyle())
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
