/// Reports the current device's iCloud account availability in Domain
/// terms. Never exposes `CKAccountStatus`.
struct CheckCloudAccountUseCase: Sendable {
    let cloudAccountStatusProvider: CloudAccountStatusProviding

    func execute() async -> CloudAccountAvailability {
        await cloudAccountStatusProvider.currentStatus()
    }
}
