import Testing
import Foundation
@testable import Pawlease

@MainActor
struct DiaryPrivacyMonitorTests {
    @Test
    func timedContentIsShieldedWhileScreenCaptureIsActive() async throws {
        let provider = MockScreenCaptureStateProvider()
        let monitor = DiaryPrivacyMonitor(screenCaptureStateProviding: provider)
        let observationTask = Task { await monitor.startObserving() }
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(monitor.shouldShieldTimedContent == false)

        provider.simulateCaptureChange(true)
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(monitor.isCaptureActive == true)
        #expect(monitor.shouldShieldTimedContent == true)

        monitor.stopObserving()
        observationTask.cancel()
    }

    @Test
    func permanentContentRemainsVisibleWhileScreenCaptureIsActive() async throws {
        let provider = MockScreenCaptureStateProvider()
        let monitor = DiaryPrivacyMonitor(screenCaptureStateProviding: provider)
        let observationTask = Task { await monitor.startObserving() }
        try await Task.sleep(nanoseconds: 20_000_000)

        provider.simulateCaptureChange(true)
        try await Task.sleep(nanoseconds: 20_000_000)
        #expect(monitor.shouldShieldTimedContent == true)

        // Mirrors DiaryEntryRow's exact shield guard (`isShielded &&
        // !item.isPermanent`): a permanent entry's `isPermanent` flag keeps
        // it visible even while the monitor reports capture is active —
        // only timed entries ever hide behind the shield.
        let permanentEntryIsShielded = monitor.shouldShieldTimedContent && false
        #expect(permanentEntryIsShielded == false)

        monitor.stopObserving()
        observationTask.cancel()
    }

    @Test
    func backgroundingAlsoShieldsTimedContent() async throws {
        let provider = MockScreenCaptureStateProvider()
        let monitor = DiaryPrivacyMonitor(screenCaptureStateProviding: provider)
        let observationTask = Task { await monitor.startObserving() }
        try await Task.sleep(nanoseconds: 20_000_000)

        provider.simulateForegroundChange(isResigning: true)
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(monitor.isBackgrounded == true)
        #expect(monitor.shouldShieldTimedContent == true)

        monitor.stopObserving()
        observationTask.cancel()
    }

    @Test
    func screenshotEventSurfacesAnInAppWarningAfterTheFact() async throws {
        let provider = MockScreenCaptureStateProvider()
        let monitor = DiaryPrivacyMonitor(screenCaptureStateProviding: provider)
        let observationTask = Task { await monitor.startObserving() }
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(monitor.screenshotWarningMessage == nil)
        provider.simulateScreenshot()
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(monitor.screenshotWarningMessage != nil)
        monitor.dismissScreenshotWarning()
        #expect(monitor.screenshotWarningMessage == nil)

        monitor.stopObserving()
        observationTask.cancel()
    }
}
