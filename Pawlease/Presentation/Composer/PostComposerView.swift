import PhotosUI
import SwiftUI

struct PostComposerView: View {
    @State private var viewModel: PostComposerViewModel
    @State private var isPhotoSourceDialogPresented = false
    @State private var isCameraPresented = false
    @State private var isPhotoLibraryPresented = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PostComposerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Share one moment")
                        .font(.title.bold())
                        .foregroundStyle(PawleaseTheme.textPrimary)
                    Text("Your photo helps meet today's 2-person survival requirement.")
                        .font(.subheadline)
                        .foregroundStyle(PawleaseTheme.textSecondary)
                }

                photoArea

                captionSection

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .foregroundStyle(PawleaseTheme.accentPrimary)
                    Text("One valid moment per member each Circle day. Published moments remain in Memories.")
                }
                .font(.footnote)
                .foregroundStyle(PawleaseTheme.textSecondary)

                if case .error(let message) = viewModel.publishState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

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
                        Text("Share Today's Moment")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PawleasePrimaryButtonStyle())
                .disabled(!viewModel.canPublish)
                .accessibilityHint(viewModel.canPublish ? "" : "Add a photo to publish")
            }
            .padding(PawleaseTheme.pagePadding)
        }
        .background(PawleaseTheme.background)
        .navigationTitle("Today's Moment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                // Not "Back" — `MomentCameraView`'s own unavailable-camera
                // state also exposes a "Back" button, and both can exist in
                // the accessibility tree at once while its `fullScreenCover`
                // is layered on top of this still-mounted composer,  making
                // `app.buttons["Back"]` ambiguous for UI tests.
                .accessibilityLabel("Dismiss Composer")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Cancel")
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            MomentCameraView { data in
                viewModel.setCapturedPhotoData(data)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { viewModel.pendingCropImage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.cancelLibraryPhotoCrop() }
                }
            )
        ) {
            if let image = viewModel.pendingCropImage {
                SquarePhotoCropView(
                    image: image,
                    onCancel: viewModel.cancelLibraryPhotoCrop,
                    onUsePhoto: viewModel.useCroppedLibraryPhoto
                )
            }
        }
        .photosPicker(
            isPresented: $isPhotoLibraryPresented,
            selection: $viewModel.selectedItem,
            matching: .images
        )
        .confirmationDialog("Add Today's Moment", isPresented: $isPhotoSourceDialogPresented, titleVisibility: .visible) {
            Button("Take Photo") { isCameraPresented = true }
            Button("Photo Library") { isPhotoLibraryPresented = true }
        } message: {
            Text("Your photo will be square.")
        }
    }

    private var photoArea: some View {
        Button {
            isPhotoSourceDialogPresented = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                photoPreview
                cameraCornerButton
                    .padding(14)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.previewImage == nil ? "Add today's photo" : "Change today's photo")
        .accessibilityHint("Choose whether to take a photo or select one from your photo library")
    }

    @ViewBuilder
    private var photoPreview: some View {
        ZStack {
            if let previewImage = viewModel.previewImage {
                previewImage
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: PawleaseTheme.cardCornerRadius)
                    .fill(PawleaseTheme.petArtworkBackground)
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(PawleaseTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: PawleaseTheme.cardCornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: PawleaseTheme.cardCornerRadius))
    }

    private var cameraCornerButton: some View {
        Image(systemName: "camera.fill")
            .font(.headline)
            .foregroundStyle(PawleaseTheme.accentPrimary)
            .frame(width: 44, height: 44)
            .background(.white, in: Circle())
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .accessibilityHidden(true)
    }

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Caption")
                    .font(.headline)
                    .foregroundStyle(PawleaseTheme.textPrimary)
                Text("Optional")
                    .font(.subheadline)
                    .foregroundStyle(PawleaseTheme.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                if viewModel.captionText.isEmpty {
                    Text("Add a short caption…")
                        .foregroundStyle(PawleaseTheme.textSecondary)
                        .padding(.top, 10)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.captionText)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .frame(minHeight: 90)
            }
            .background(PawleaseTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(PawleaseTheme.divider, lineWidth: 1)
            )
            .accessibilityLabel("Optional caption")

            Text(viewModel.viewState.characterCountLabel)
                .font(.caption)
                .foregroundStyle(viewModel.viewState.isCaptionValid ? PawleaseTheme.textSecondary : Color.red)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("\(viewModel.viewState.characterCountLabel) characters used")
        }
    }
}
