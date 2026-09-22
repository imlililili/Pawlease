import CloudKit

/// Reports iCloud account availability using `CKContainer.accountStatus()`.
final class CloudKitAccountStatusProvider: CloudAccountStatusProviding, @unchecked Sendable {
    private let container: CKContainer

    init(containerIdentifier: String = PersistenceController.cloudKitContainerIdentifier) {
        self.container = CKContainer(identifier: containerIdentifier)
    }

    func currentStatus() async -> CloudAccountAvailability {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available: return .available
            case .noAccount: return .noAccount
            case .restricted: return .restricted
            case .temporarilyUnavailable: return .temporarilyUnavailable
            case .couldNotDetermine: return .unknown
            @unknown default: return .unknown
            }
        } catch {
            // No account, no network, or CloudKit misconfigured — the app
            // must still launch, so this degrades to "unknown" rather than
            // throwing.
            return .unknown
        }
    }
}
