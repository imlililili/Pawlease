import Foundation

/// One member's photo for a single `CircleDay`, with an optional short caption.
/// A member may have at most one `DailyMoment` per Circle day. `moodEmoji` is
/// retained only to decode legacy synced records and is nil for new Moments.
struct DailyMoment: Sendable, Equatable, Identifiable {
    let id: UUID
    let circleID: UUID
    let authorProfileID: UUID
    let authorNameSnapshot: String
    let day: CircleDay
    let caption: MomentCaption
    let moodEmoji: String?
    let photo: MomentPhoto
    let createdAt: Date
}
