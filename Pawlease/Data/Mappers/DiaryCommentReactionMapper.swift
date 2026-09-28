import Foundation

enum DiaryCommentReactionMapper {
    static func toDomain(_ entity: DiaryCommentReactionEntity) throws -> DiaryCommentReaction {
        guard let emojiValue = entity.emoji else {
            throw DomainValidationError.invalidDiaryReactionEmoji
        }
        return DiaryCommentReaction(
            id: entity.id ?? UUID(),
            commentID: entity.diaryComment?.id ?? UUID(),
            memberProfileID: entity.authorProfileID ?? UUID(),
            emoji: try DiaryReactionEmoji(emojiValue),
            createdAt: entity.createdAt ?? Date()
        )
    }

    static func apply(_ reaction: DiaryCommentReaction, to entity: DiaryCommentReactionEntity) {
        entity.id = reaction.id
        entity.authorProfileID = reaction.memberProfileID
        entity.emoji = reaction.emoji.value
        entity.createdAt = reaction.createdAt
    }
}
