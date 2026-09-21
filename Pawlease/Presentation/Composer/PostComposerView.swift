import PhotosUI
import SwiftUI

struct PostComposerView: View {
    @State private var viewModel: PostComposerViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PostComposerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                    photoPreview
                }
                .accessibilityLabel(viewModel.previewImage == nil ? "Choose a photo" : "Change photo")
            }

            Section {
                TextField("What's happening today?", text: $viewModel.captionText, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityLabel("Caption")
                HStack {
                    Spacer()
                    Text(viewModel.viewState.characterCountLabel)
                        .font(.caption)
                        .foregroundStyle(viewModel.viewState.isCaptionValid ? Color.secondary : Color.red)
                        .accessibilityLabel("\(viewModel.viewState.characterCountLabel) characters used")
                }
            } header: {
                Text("Caption")
            }

            Section("Mood (optional)") {
                MoodPicker(options: viewModel.moodOptions, selection: $viewModel.selectedMood)
            }

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
                .accessibilityHint(viewModel.canPublish ? "" : "Add a photo and a caption to publish")
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
            ContentUnavailableView("Select a Photo", systemImage: "photo.badge.plus")
                .frame(height: 220)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct MoodPicker: View {
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { emoji in
                    Button {
                        selection = (selection == emoji) ? nil : emoji
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .padding(8)
                            .background(
                                Circle().fill(selection == emoji ? Color.accentColor.opacity(0.3) : .clear)
                            )
                    }
                    .accessibilityLabel("Mood \(emoji)")
                    .accessibilityAddTraits(selection == emoji ? .isSelected : [])
                }
            }
        }
    }
}
