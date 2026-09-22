import Foundation

/// Reports where a Circle stands in the CloudKit sharing lifecycle.
struct LoadCircleSharingStateUseCase: Sendable {
    let circleSharingRepository: CircleSharingRepository

    func execute(circleID: UUID) async throws -> CircleSharingState {
        try await circleSharingRepository.sharingState(circleID: circleID)
    }
}
