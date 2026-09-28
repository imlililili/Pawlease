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
        Form {
            Section {
                Button {
                    isPhotoSourceDialogPresented = true
                } label: {
                    photoPreview
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.previewImage == nil ? "Add today's photo" : "Change today's photo")
                .accessibilityHint("Choose whether to take a photo or select one from your photo library")
            }

            Section {
                TextField("Add a caption (optional)", text: $viewModel.captionText, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityLabel("Optional caption")
                HStack {
                    Spacer()
                    Text(viewModel.viewState.characterCountLabel)
                        .font(.caption)
                        .foregroundStyle(viewModel.viewState.isCaptionValid ? Color.secondary : Color.red)
                        .accessibilityLabel("\(viewModel.viewState.characterCountLabel) characters used")
                }
            } header: { Text("Caption (optional)") }

            if case .error(let message) = viewModel.publishState {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Today's Moment")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
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
                .accessibilityHint(viewModel.canPublish ? "" : "Add a photo to publish")
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
        .overlay {
            if isPhotoSourceDialogPresented {
                photoSourceDialog
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: isPhotoSourceDialogPresented)
    }

    @ViewBuilder
    private var photoPreview: some View {
        ZStack {
            if let previewImage = viewModel.previewImage {
                previewImage
                    .resizable()
                    .scaledToFill()
            } else {
                ContentUnavailableView("Add Today's Photo", systemImage: "camera.fill")
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private var photoSourceDialog: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    isPhotoSourceDialogPresented = false
                }

            VStack(spacing: 0) {
                Button("Take Photo") {
                    isPhotoSourceDialogPresented = false
                    isCameraPresented = true
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)

                Divider()

                Button("Photo Library") {
                    isPhotoSourceDialogPresented = false
                    isPhotoLibraryPresented = true
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
            }
            .buttonStyle(.plain)
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(width: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Photo source")
        }
    }
}
