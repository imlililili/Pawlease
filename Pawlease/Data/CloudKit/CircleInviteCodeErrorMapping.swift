import CloudKit

/// Maps `CKError` into the semantic `CircleInviteCodeError` Domain/
/// Application/Presentation actually see. This is the one place
/// `CKError.Code` is inspected for the invite-code workflow.
enum CircleInviteCodeErrorMapping {
    static func map(_ error: Error) -> CircleInviteCodeError {
        guard let ckError = error as? CKError else {
            return .unknown(message: error.localizedDescription)
        }

        switch ckError.code {
        case .unknownItem:
            return .notFound
        case .networkUnavailable, .networkFailure:
            return .offline
        case .notAuthenticated:
            return .accountUnavailable
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return .offline
        case .permissionFailure:
            return .permissionFailure
        case .serverRecordChanged:
            return .collision
        default:
            return .unknown(message: ckError.localizedDescription)
        }
    }
}
