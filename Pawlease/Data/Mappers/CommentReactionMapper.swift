import Foundation

enum CommentReactionMapper {
    static func toDomain(_ entity: CommentReactionEntity) throws -> CommentReaction {
        guard let emojiValue = entity.emoji, let emoji = ReactionEmoji(rawValue: emojiValue) else {
            throw DomainValidationError.invalidReactionEmoji
        }
        return CommentReaction(
            id: entity.id ?? UUID(),
            commentID: entity.comment?.id ?? UUID(),
            memberProfileID: entity.authorProfileID ?? UUID(),
            emoji: emoji,
            createdAt: entity.createdAt ?? Date()
        )
    }

    static func apply(_ reaction: CommentReaction, to entity: CommentReactionEntity) {
        entity.id = reaction.id
        entity.authorProfileID = reaction.memberProfileID
        entity.emoji = reaction.emoji.rawValue
        entity.createdAt = reaction.createdAt
    }
}
