import Foundation

/// Prepares a Circle for invitation: requires an available iCloud account,
/// then asks the repository to create or reuse the Circle's `CKShare`. The
/// repository itself is responsible for reusing an existing share rather
/// than creating a duplicate.
struct PrepareCircleInvitationUseCase: Sendable {
    let cloudAccountStatusProvider: CloudAccountStatusProviding
    let circleSharingRepository: CircleSharingRepository

    func execute(circleID: UUID) async throws -> PreparedCircleShare {
        let status = await cloudAccountStatusProvider.currentStatus()
        guard status.allowsSharing else {
            throw CircleSharingError.iCloudAccountUnavailable(status)
        }
        return try await circleSharingRepository.prepareShare(circleID: circleID)
    }
}
