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
        entity.joinedAt = member.joinedAt
        applyMutableFields(member, to: entity)
    }

    /// Fields that may legitimately change after a member first joins
    /// (name, avatar, role). Deliberately excludes `id` and `joinedAt` —
    /// when an existing member row is found and updated in place (see
    /// `CoreDataMemberRepository.saveMember`), those must stay stable
    /// across repeated, idempotent saves rather than being overwritten by
    /// whatever fresh values the caller happened to pass this time.
    static func applyMutableFields(_ member: CircleMember, to entity: MemberEntity) {
        entity.profileID = member.profileID
        entity.displayName = member.displayName
        entity.avatarEmoji = member.avatarEmoji
        entity.role = member.role.rawValue
    }
}
