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
}
