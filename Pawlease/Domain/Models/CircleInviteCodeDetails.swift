import Foundation

/// Everything resolved from a public `CircleInviteCode` lookup record,
/// already defensively validated by the Data layer (expected record type,
/// HTTPS CKShare URL, valid Circle UUID, supported schema version) before
/// this value is ever constructed. This is only a lookup result — it is
/// never, by itself, proof of Circle membership authorization. Real
/// authorization only happens through Apple's CKShare acceptance flow.
struct CircleInviteCodeDetails: Sendable, Equatable {
    let code: CircleInviteCode
    let circleID: UUID
    let shareURL: URL
    let createdAt: Date
    let expiresAt: Date
    let isRevoked: Bool

    func isExpired(asOf now: Date) -> Bool {
        now >= expiresAt
    }
}
