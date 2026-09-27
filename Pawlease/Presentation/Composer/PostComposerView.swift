import PhotosUI
import SwiftUI

struct PostComposerView: View {
    @State private var viewModel: PostComposerViewModel
    @State private var isCameraPresented = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PostComposerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                photoPreview

                HStack {
                    Button {
                        isCameraPresented = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
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
