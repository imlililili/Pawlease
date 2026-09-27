@preconcurrency import AVFoundation
import Foundation
import Observation

/// Owns the native camera session used by Moment capture. UI state is kept on
/// the main actor while AVFoundation starts and stops its blocking session off
/// the main thread.
@MainActor
@Observable
final class MomentCamera: NSObject {
    enum State: Equatable {
        case idle
        case requestingPermission
        case ready
        case unavailable
        case denied
        case failed(String)
    }

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var captureContinuation: CheckedContinuation<Data?, Never>?
    private var isConfigured = false

    private(set) var state: State = .idle
    private(set) var isCapturing = false
    private(set) var cameraPosition: AVCaptureDevice.Position = .back

    func configure() async {
        guard !isConfigured else {
            state = .ready
            return
        }
        guard Self.hasCamera else {
            state = .unavailable
            return
        }

        state = .requestingPermission
        guard await requestAccess() else {
            state = .denied
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let device = cameraDevice(for: cameraPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(photoOutput) else {
            state = .failed("The camera couldn't be configured.")
            return
        }

        session.addInput(input)
        currentInput = input
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality
        isConfigured = true
        state = .ready
    }

    func start() {
        guard isConfigured, !session.isRunning else { return }
        let session = session
        Task.detached(priority: .userInitiated) {
            session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        let session = session
        Task.detached(priority: .utility) {
            session.stopRunning()
        }
    }

    func capturePhoto() async -> Data? {
        guard state == .ready, !isCapturing else { return nil }
        isCapturing = true

        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality

        return await withCheckedContinuation { continuation in
            captureContinuation = continuation
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func switchCamera() {
        guard isConfigured else { return }
        let nextPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        guard let device = cameraDevice(for: nextPosition),
              let newInput = try? AVCaptureDeviceInput(device: device) else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if let currentInput {
            session.removeInput(currentInput)
        }
        guard session.canAddInput(newInput) else {
            if let currentInput, session.canAddInput(currentInput) {
                session.addInput(currentInput)
            }
            return
        }
        session.addInput(newInput)
        currentInput = newInput
        cameraPosition = nextPosition
    }

    static var hasCamera: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    private func cameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    private func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

extension MomentCamera: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        Task { @MainActor in
            isCapturing = false
            if data == nil {
                state = .failed("The photo couldn't be captured. Please try again.")
            }
            captureContinuation?.resume(returning: data)
            captureContinuation = nil
        }
    }
}
