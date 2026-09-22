import Foundation
@testable import Pawlease

/// Configurable test double for `WidgetSnapshotStoring`: stubbed results,
/// injectable errors, captured arguments, and invocation counts.
final class MockWidgetSnapshotStore: WidgetSnapshotStoring, @unchecked Sendable {
    var saveError: Error?
    private(set) var savedSnapshots: [WidgetSnapshot] = []
    private(set) var saveCallCount = 0

    var stubbedLoadSnapshot: WidgetSnapshot = .placeholder
    private(set) var loadSnapshotCallCount = 0

    func save(_ snapshot: WidgetSnapshot) throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        savedSnapshots.append(snapshot)
    }

    func loadSnapshot() -> WidgetSnapshot {
        loadSnapshotCallCount += 1
        return stubbedLoadSnapshot
    }
}
