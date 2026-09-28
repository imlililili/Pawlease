import Foundation
import Observation

/// Drives the timed-Diary-entry privacy shield from an injected
/// `ScreenCaptureStateProviding`, so Presentation logic never touches
/// `UIScreen`/`UIApplication` directly and can be exercised in tests with a
/// mock. Shared by the Feed, Detail, and Archive ViewModels — anywhere a
/// timed entry's text renders.
///
/// Honestly documented limitation: this can react to screen recording,
/// AirPlay/mirroring, and backgrounding, and can warn *after* a screenshot
/// was taken — but iOS has no public API to detect or block a screenshot
/// before it happens. `shouldShieldTimedContent` never claims to prevent
/// that; it only covers the capture states Apple's APIs can actually report
/// live.
@MainActor
@Observable
final class DiaryPrivacyMonitor {
    private(set) var isCaptureActive: Bool
    private(set) var isBackgrounded = false
    private(set) var screenshotWarningMessage: String?

    /// Whether a timed entry's real body text should be replaced with a
    /// privacy shield right now. Permanent entries never consult this.
    var shouldShieldTimedContent: Bool {
        isCaptureActive || isBackgrounded
    }

    private let screenCaptureStateProviding: ScreenCaptureStateProviding
    private var observationTask: Task<Void, Never>?

    init(screenCaptureStateProviding: ScreenCaptureStateProviding) {
        self.screenCaptureStateProviding = screenCaptureStateProviding
        self.isCaptureActive = screenCaptureStateProviding.isCaptureActive
    }

    /// Starts observing platform signals. Safe to call repeatedly — a
    /// second call while already observing is a no-op. Intended to run
    /// from a View's `.task`, which cancels it automatically on disappear.
    func startObserving() async {
        guard observationTask == nil else { return }
        let task = Task { [weak self] in
            guard let self else { return }
            async let captureTask: Void = self.observeCaptureChanges()
            async let foregroundTask: Void = self.observeForegroundChanges()
            async let screenshotTask: Void = self.observeScreenshotEvents()
            _ = await (captureTask, foregroundTask, screenshotTask)
        }
        observationTask = task
        await task.value
    }

    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }

    func dismissScreenshotWarning() {
        screenshotWarningMessage = nil
    }

    private func observeCaptureChanges() async {
        for await isCaptured in screenCaptureStateProviding.captureStateChanges() {
            isCaptureActive = isCaptured
        }
    }

    private func observeForegroundChanges() async {
        for await isResigning in screenCaptureStateProviding.foregroundStateChanges() {
            isBackgrounded = isResigning
        }
    }

    private func observeScreenshotEvents() async {
        for await _ in screenCaptureStateProviding.screenshotEvents() {
            screenshotWarningMessage = "A screenshot was taken. Anything shared here may no longer be private."
        }
    }
}
