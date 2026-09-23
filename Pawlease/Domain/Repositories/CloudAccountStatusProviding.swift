/// Reports the current device's iCloud account state in Domain terms.
/// Implemented in the Data layer using `CKContainer.accountStatus()` —
/// nothing above Data ever sees `CKAccountStatus`.
protocol CloudAccountStatusProviding: Sendable {
    func currentStatus() async -> CloudAccountAvailability
}
