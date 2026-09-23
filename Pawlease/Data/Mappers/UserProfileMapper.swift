import Foundation

enum UserProfileMapper {
    static func toDomain(_ entity: UserProfileEntity) -> UserProfile {
        UserProfile(
            id: entity.id ?? UUID(),
            displayName: entity.displayName ?? "",
            avatarEmoji: entity.avatarEmoji ?? "🙂",
            createdAt: entity.createdAt ?? Date()
        )
    }

    static func apply(_ profile: UserProfile, to entity: UserProfileEntity) {
        entity.id = profile.id
        entity.displayName = profile.displayName
        entity.avatarEmoji = profile.avatarEmoji
        entity.createdAt = profile.createdAt
    }
}
