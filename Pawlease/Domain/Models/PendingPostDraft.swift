import Foundation

/// A locally-saved draft awaiting review in the Post Composer — created by
/// importing a Share Extension inbox item (and, in a later phase, possibly
/// other sources). `localImagePath` is a relative filename resolved
/// through the same App Group share inbox the extension wrote to; this
/// type never carries a Core Data managed object or raw image bytes.
struct PendingPostDraft: Sendable, Equatable, Identifiable {
    let id: UUID
    let caption: String?
    let localImagePath: String
    let createdAt: Date
    let source: String
}
