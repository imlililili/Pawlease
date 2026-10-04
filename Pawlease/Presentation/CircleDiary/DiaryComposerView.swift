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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        authorRow
                        textEditorSection
                        visibilitySection

                        if case .error(let message) = viewModel.publishState {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(PawleaseTheme.pagePadding)
                }

                Divider()
                    .overlay(PawleaseTheme.divider)

                actionRow
                    .padding(PawleaseTheme.pagePadding)
            }
            .background(PawleaseTheme.background)
            .navigationTitle("New Diary Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        attemptDismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Back")
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

    private var authorRow: some View {
        HStack(spacing: 12) {
            AvatarView(name: viewModel.author.displayName, identitySeed: viewModel.author.profileID.uuidString, diameter: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.author.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PawleaseTheme.textPrimary)
                Text("Posting to \(viewModel.circleName)")
                    .font(.subheadline)
                    .foregroundStyle(PawleaseTheme.textSecondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var textEditorSection: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ZStack(alignment: .topLeading) {
                if viewModel.bodyText.isEmpty {
                    Text("What's happening in your Circle?")
                        .font(.title3)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.bodyText)
                    .font(.title3)
                    .foregroundStyle(PawleaseTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 220)
            }
            .accessibilityLabel("Diary entry text")

            Text(viewModel.characterCountLabel)
                .font(.caption)
                .foregroundStyle(viewModel.isBodyValid || viewModel.bodyText.isEmpty ? PawleaseTheme.textSecondary : .red)
                .accessibilityLabel("\(viewModel.characterCountLabel) characters used")
        }
    }

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visibility")
                .font(.headline)
                .foregroundStyle(PawleaseTheme.textPrimary)

            // A plain 2x2 grid, not `LazyVGrid` — there are only ever 4
            // fixed options, and `LazyVGrid` can leave off-screen cells
            // (e.g. hidden below the system keyboard while the text editor
            // above has focus) uninstantiated, making them briefly
            // undiscoverable to both VoiceOver and UI test automation.
            VStack(spacing: 12) {
                visibilityRow(DiaryVisibilityDuration.oneDay, DiaryVisibilityDuration.threeDays)
                visibilityRow(DiaryVisibilityDuration.sevenDays, DiaryVisibilityDuration.permanent)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "clock")
                Text(viewModel.visibilityExplanation)
            }
            .font(.footnote)
            .foregroundStyle(PawleaseTheme.textSecondary)
        }
    }

    private func visibilityRow(_ first: DiaryVisibilityDuration, _ second: DiaryVisibilityDuration) -> some View {
        HStack(spacing: 12) {
            visibilityButton(first)
            visibilityButton(second)
        }
    }

    private func visibilityButton(_ duration: DiaryVisibilityDuration) -> some View {
        Button(duration.displayName) {
            viewModel.visibilityDuration = duration
        }
        .buttonStyle(PawleaseSelectablePillButtonStyle(isSelected: viewModel.visibilityDuration == duration))
        .accessibilityAddTraits(viewModel.visibilityDuration == duration ? [.isSelected] : [])
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button("Cancel") { attemptDismiss() }
                .buttonStyle(PawleaseSecondaryButtonStyle())
                .frame(maxWidth: .infinity)

            Button {
                Task {
                    await viewModel.publish()
                    if viewModel.didPublish { dismiss() }
                }
            } label: {
                if viewModel.publishState == .publishing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Publish")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PawleasePrimaryButtonStyle())
            .disabled(!viewModel.canPublish)
            .accessibilityHint(viewModel.canPublish ? "" : "Write something to publish")
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
