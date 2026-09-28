import UIKit

/// Live `ScreenCaptureStateProviding` backed entirely by documented,
/// public UIKit APIs: `UIScreen.isCaptured` / `capturedDidChangeNotification`
/// for recording/AirPlay/mirroring, `UIApplication
/// .userDidTakeScreenshotNotification` for after-the-fact screenshot
/// detection, and `UIApplication.willResignActiveNotification` /
/// `.didBecomeActiveNotification` for the app-switcher/background case.
final class SystemScreenCaptureStateProvider: ScreenCaptureStateProviding {
    @MainActor
    var isCaptureActive: Bool {
        UIScreen.main.isCaptured
    }

    func captureStateChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await _ in NotificationCenter.default.notifications(named: UIScreen.capturedDidChangeNotification) {
                    continuation.yield(UIScreen.main.isCaptured)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func screenshotEvents() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await _ in NotificationCenter.default.notifications(named: UIApplication.userDidTakeScreenshotNotification) {
                    continuation.yield(())
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func foregroundStateChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let resignTask = Task {
                for await _ in NotificationCenter.default.notifications(named: UIApplication.willResignActiveNotification) {
                    continuation.yield(true)
                }
            }
            let activeTask = Task {
                for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                    continuation.yield(false)
                }
            }
            continuation.onTermination = { _ in
                resignTask.cancel()
                activeTask.cancel()
            }
        }
    }
}
