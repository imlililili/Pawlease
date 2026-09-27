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
        .confirmationDialog(
            "Add Today's Photo",
            isPresented: $isPhotoSourceDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Take Photo") {
                isCameraPresented = true
            }
            Button("Photo Library") {
                isPhotoLibraryPresented = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $isPhotoLibraryPresented,
            selection: $viewModel.selectedItem,
            matching: .images
        )
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let previewImage = viewModel.previewImage {
            previewImage
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            ContentUnavailableView("Add Today's Photo", systemImage: "camera.fill")
                .frame(height: 220)
                .frame(maxWidth: .infinity)
        }
    }
}
