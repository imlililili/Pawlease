import Foundation
@testable import Pawlease

/// Configurable test double for `ScreenCaptureStateProviding`: lets a test
/// simulate capture/screenshot/foreground events without touching
/// `UIScreen` or `UIApplication`.
final class MockScreenCaptureStateProvider: ScreenCaptureStateProviding, @unchecked Sendable {
    @MainActor var isCaptureActive: Bool = false

    private var captureContinuation: AsyncStream<Bool>.Continuation?
    private var screenshotContinuation: AsyncStream<Void>.Continuation?
    private var foregroundContinuation: AsyncStream<Bool>.Continuation?

    func captureStateChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            self.captureContinuation = continuation
        }
    }

    func screenshotEvents() -> AsyncStream<Void> {
        AsyncStream { continuation in
            self.screenshotContinuation = continuation
        }
    }

    func foregroundStateChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            self.foregroundContinuation = continuation
        }
    }

    func simulateCaptureChange(_ isCaptured: Bool) {
        captureContinuation?.yield(isCaptured)
    }

    func simulateScreenshot() {
        screenshotContinuation?.yield(())
    }

    func simulateForegroundChange(isResigning: Bool) {
        foregroundContinuation?.yield(isResigning)
    }
}
