import CloudKit

/// Maps `CKError` (and any other error a CloudKit-adjacent call might
/// throw) into the semantic `CircleSharingError` Domain/Application/
/// Presentation actually see. This is the one place `CKError.Code` is
/// inspected in the whole app.
enum CircleSharingErrorMapping {
    static func map(_ error: Error) -> CircleSharingError {
        guard let ckError = error as? CKError else {
            return .unknown(message: error.localizedDescription)
        }

        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .requestRateLimited:
            return .rateLimited
        case .serviceUnavailable, .notAuthenticated:
            return .serviceUnavailable
        case .zoneNotFound, .userDeletedZone:
            return .zoneUnavailable
        case .alreadyShared:
            return .shareAlreadyExists
        case .partialFailure:
            return .unknown(message: "Some changes couldn't sync. Please try again.")
        default:
            return .unknown(message: ckError.localizedDescription)
        }
    }
}
