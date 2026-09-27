import Foundation

/// Confirms a `CKShare` exists and is ready to present, without carrying
/// the `CKShare` itself — Domain and Application never see CloudKit types.
/// The Presentation layer uses `circleID` to ask an Infrastructure-layer
/// adapter for the actual native sharing controller.
struct PreparedCircleShare: Sendable, Equatable {
    let circleID: UUID
    /// `true` if this call created a brand-new share; `false` if an
    /// existing share was reused. Lets the UI say "Invite friends" vs.
    /// "Manage invitation" without re-deriving that from CloudKit state.
    let isNewShare: Bool
    /// The `CKShare`'s saved URL, if CloudKit has assigned one yet — `nil`
    /// only in the rare case a share exists but hasn't finished saving.
    /// `CreateCircleInviteCodeUseCase` requires this before publishing an
    /// invite-code record.
    let shareURL: URL?

    init(circleID: UUID, isNewShare: Bool, shareURL: URL? = nil) {
        self.circleID = circleID
        self.isNewShare = isNewShare
        self.shareURL = shareURL
    }
}
