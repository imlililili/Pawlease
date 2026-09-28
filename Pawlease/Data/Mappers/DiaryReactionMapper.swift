import Foundation

enum DiaryReactionMapper {
    static func toDomain(_ entity: DiaryReactionEntity) throws -> DiaryReaction {
        guard let emojiValue = entity.emoji else {
            throw DomainValidationError.invalidDiaryReactionEmoji
        }
        return DiaryReaction(
            id: entity.id ?? UUID(),
            entryID: entity.diaryEntry?.id ?? UUID(),
            memberProfileID: entity.authorProfileID ?? UUID(),
            emoji: try DiaryReactionEmoji(emojiValue),
            createdAt: entity.createdAt ?? Date()
        )
    }

    static func apply(_ reaction: DiaryReaction, to entity: DiaryReactionEntity) {
        entity.id = reaction.id
        entity.authorProfileID = reaction.memberProfileID
        entity.emoji = reaction.emoji.value
        entity.createdAt = reaction.createdAt
    }
}
