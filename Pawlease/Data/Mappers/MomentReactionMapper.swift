import Foundation

enum MomentReactionMapper {
    static func toDomain(_ entity: PostReactionEntity) throws -> MomentReaction {
        guard let emojiValue = entity.emoji, let emoji = ReactionEmoji(rawValue: emojiValue) else {
            throw DomainValidationError.invalidReactionEmoji
        }
        return MomentReaction(
            id: entity.id ?? UUID(),
            momentID: entity.dailyPost?.id ?? UUID(),
            memberProfileID: entity.authorProfileID ?? UUID(),
            emoji: emoji,
            createdAt: entity.createdAt ?? Date()
        )
    }

    static func apply(_ reaction: MomentReaction, to entity: PostReactionEntity) {
        entity.id = reaction.id
        entity.authorProfileID = reaction.memberProfileID
        entity.emoji = reaction.emoji.rawValue
        entity.createdAt = reaction.createdAt
    }
}
