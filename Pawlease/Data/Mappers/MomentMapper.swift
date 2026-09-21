import Foundation

enum MomentMapper {
    static func toDomain(_ entity: DailyPostEntity) throws -> DailyMoment {
        DailyMoment(
            id: entity.id ?? UUID(),
            circleID: entity.circle?.id ?? UUID(),
            authorProfileID: entity.authorProfileID ?? UUID(),
            authorNameSnapshot: entity.authorNameSnapshot ?? "",
            day: CircleDay(value: entity.dayKey ?? ""),
            caption: try MomentCaption(entity.caption ?? ""),
            moodEmoji: entity.moodEmoji,
            photo: try MomentPhoto(
                imageData: entity.imageData ?? Data(),
                thumbnailData: entity.thumbnailData ?? Data()
            ),
            createdAt: entity.createdAt ?? Date()
        )
    }

    /// Sets `syncState` to `"local"` on every apply: Phase 1 is fully
    /// local-first, so every saved moment is, by definition, saved locally.
    /// CloudKit sync states arrive in a later phase.
    static func apply(_ moment: DailyMoment, to entity: DailyPostEntity) {
        entity.id = moment.id
        entity.authorProfileID = moment.authorProfileID
        entity.authorNameSnapshot = moment.authorNameSnapshot
        entity.dayKey = moment.day.value
        entity.caption = moment.caption.value
        entity.moodEmoji = moment.moodEmoji
        entity.imageData = moment.photo.imageData
        entity.thumbnailData = moment.photo.thumbnailData
        entity.createdAt = moment.createdAt
        entity.syncState = "local"
    }
}
