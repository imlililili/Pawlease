import Foundation

enum MemberMapper {
    static func toDomain(_ entity: MemberEntity) -> CircleMember {
        CircleMember(
            id: entity.id ?? UUID(),
            circleID: entity.circle?.id ?? UUID(),
            profileID: entity.profileID ?? UUID(),
            displayName: entity.displayName ?? "",
            avatarEmoji: entity.avatarEmoji ?? "🙂",
            joinedAt: entity.joinedAt ?? Date(),
            role: CircleMemberRole(rawValue: entity.role ?? "") ?? .member
        )
    }

    static func apply(_ member: CircleMember, to entity: MemberEntity) {
        entity.id = member.id
        entity.profileID = member.profileID
        entity.displayName = member.displayName
        entity.avatarEmoji = member.avatarEmoji
        entity.joinedAt = member.joinedAt
        entity.role = member.role.rawValue
    }
}
