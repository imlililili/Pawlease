/// A human-readable summary of a pending or accepted Circle invitation,
/// safe to display in Presentation without exposing `CKShare.Metadata`.
struct CircleInvitationSummary: Sendable, Equatable {
    let circleName: String
    let ownerDisplayName: String?
}
