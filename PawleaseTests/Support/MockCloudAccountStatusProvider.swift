import Foundation
@testable import Pawlease

/// Configurable test double for `CloudAccountStatusProviding`: stubbed
/// result and invocation count.
final class MockCloudAccountStatusProvider: CloudAccountStatusProviding, @unchecked Sendable {
    var stubbedStatus: CloudAccountAvailability = .available
    private(set) var currentStatusCallCount = 0

    func currentStatus() async -> CloudAccountAvailability {
        currentStatusCallCount += 1
        return stubbedStatus
    }
}
