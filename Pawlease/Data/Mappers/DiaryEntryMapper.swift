import Foundation

enum DiaryEntryMapper {
    static func toDomain(_ entity: DiaryEntryEntity) throws -> DiaryEntry {
        guard let visibilityDurationRaw = entity.visibilityDuration,
              let visibilityDuration = DiaryVisibilityDuration(rawValue: visibilityDurationRaw)
        else {
            throw DomainError.diaryEntryCorrupted
        }
        return DiaryEntry(
            id: entity.id ?? UUID(),
            circleID: entity.circle?.id ?? UUID(),
            authorProfileID: entity.authorProfileID ?? UUID(),
            authorNameSnapshot: entity.authorNameSnapshot ?? "",
            authorAvatarSnapshot: entity.authorAvatarSnapshot ?? "",
            body: try DiaryEntryBody(entity.body ?? ""),
            visibilityDuration: visibilityDuration,
            createdAt: entity.createdAt ?? Date(),
            expiresAt: entity.expiresAt,
            isDeleted: entity.isSoftDeleted,
            deletedAt: entity.deletedAt
        )
    }

    static func apply(_ entry: DiaryEntry, to entity: DiaryEntryEntity) {
        entity.id = entry.id
        entity.authorProfileID = entry.authorProfileID
        entity.authorNameSnapshot = entry.authorNameSnapshot
        entity.authorAvatarSnapshot = entry.authorAvatarSnapshot
        entity.body = entry.body.value
        entity.visibilityDuration = entry.visibilityDuration.rawValue
        entity.createdAt = entry.createdAt
        entity.expiresAt = entry.expiresAt
        entity.isSoftDeleted = entry.isDeleted
        entity.deletedAt = entry.deletedAt
    }
}
