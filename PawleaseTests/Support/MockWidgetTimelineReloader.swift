@testable import Pawlease

/// Configurable test double for `WidgetTimelineReloading`: captured
/// arguments and invocation count.
final class MockWidgetTimelineReloader: WidgetTimelineReloading, @unchecked Sendable {
    private(set) var reloadCallCount = 0
    private(set) var reloadedKinds: [String] = []

    func reloadTimelines(ofKind kind: String) {
        reloadCallCount += 1
        reloadedKinds.append(kind)
    }
}
