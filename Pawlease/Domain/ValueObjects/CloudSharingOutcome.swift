/// The result of presenting the native `UICloudSharingController`, mapped to
/// a Domain-safe value before it ever reaches a ViewModel. Cancellation is
/// deliberately distinct from failure — the user backing out of the sheet
/// is not an error.
enum CloudSharingOutcome: Sendable, Equatable {
    case saved
    case stoppedSharing
    case cancelled
    case failed(CircleSharingError)
}
