import SwiftUI
import UIKit

struct MomentCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var camera = MomentCamera()

    let onCapture: (Data) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            cameraContent
        }
        .task {
            await camera.configure()
            camera.start()
        }
        .onDisappear { camera.stop() }
    }

    @ViewBuilder
    private var cameraContent: some View {
        switch camera.state {
        case .idle, .requestingPermission:
            ProgressView("Preparing Camera…")
                .tint(.white)
                .foregroundStyle(.white)
        case .ready:
            preview
        case .unavailable:
            unavailableView(
                title: "Camera Unavailable",
                message: "This device doesn't have an available camera. Choose a photo from the Moment composer instead.",
                showSettings: false
            )
        case .denied:
            unavailableView(
                title: "Camera Access Is Off",
                message: "Allow camera access in Settings to take a Moment photo.",
                showSettings: true
            )
        case .failed(let message):
            unavailableView(title: "Camera Error", message: message, showSettings: false)
        }
    }

    private var preview: some View {
        ZStack {
            MomentCameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    Spacer()
                    Button {
                        camera.switchCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .accessibilityLabel("Switch camera")
                }
                .padding()

                Spacer()

                Button {
                    Task {
                        guard let data = await camera.capturePhoto() else { return }
                        camera.stop()
                        onCapture(data)
                        dismiss()
                    }
                } label: {
                    ZStack {
                        Circle().fill(.white).frame(width: 72, height: 72)
                        Circle().stroke(.white.opacity(0.7), lineWidth: 4).frame(width: 84, height: 84)
                        if camera.isCapturing {
                            ProgressView().tint(.black)
                        }
                    }
                }
                .disabled(camera.isCapturing)
                .accessibilityLabel("Take photo")
                .padding(.bottom, 28)
            }
        }
    }

    private func unavailableView(title: String, message: String, showSettings: Bool) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "camera.fill")
                .foregroundStyle(.white)
        } description: {
            Text(message).foregroundStyle(.white.opacity(0.8))
        } actions: {
            if showSettings {
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .buttonStyle(.borderedProminent)
            }
            Button("Back") { dismiss() }
                .buttonStyle(.bordered)
                .tint(.white)
        }
    }
}
