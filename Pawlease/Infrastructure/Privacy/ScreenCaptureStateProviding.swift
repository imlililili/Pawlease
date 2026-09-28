import Foundation

/// Abstracts the platform's screen-capture and screenshot signals so
/// Presentation logic (the timed-Diary-entry privacy shield) can be tested
/// without touching `UIScreen` or `UIApplication` directly.
///
/// `isCaptureActive` covers screen recording, AirPlay mirroring, and
/// external-display mirroring together — that's exactly what Apple's
/// `UIScreen.isCaptured` documents itself as reporting, so one property
/// (and one change notification) is enough to satisfy "detect active
/// screen recording, AirPlay, and screen mirroring."
///
/// Important, honestly-documented limitation: none of this can detect or
/// prevent a screenshot *before* it happens — iOS has no public API for
/// that. `screenshotEvents()` only reports that one was already taken, for
/// an after-the-fact in-app warning.
protocol ScreenCaptureStateProviding: Sendable {
    @MainActor var isCaptureActive: Bool { get }
    /// Emits the new `isCaptureActive` value whenever screen recording,
    /// AirPlay mirroring, or external-display mirroring starts or stops.
    func captureStateChanges() -> AsyncStream<Bool>
    /// Emits once each time the system reports the user took a screenshot.
    /// Never fires *before* the screenshot — see the type's documentation.
    func screenshotEvents() -> AsyncStream<Void>
    /// Emits `true` when the app is about to leave the foreground (app
    /// switcher, backgrounding) and `false` when it's fully active again —
    /// used to hide timed-entry content before the system takes the app
    /// switcher's own snapshot.
    func foregroundStateChanges() -> AsyncStream<Bool>
}
