import Foundation

enum DiaryCommentMapper {
    static func toDomain(_ entity: DiaryCommentEntity) throws -> DiaryComment {
        DiaryComment(
            id: entity.id ?? UUID(),
            entryID: entity.diaryEntry?.id ?? UUID(),
            authorProfileID: entity.authorProfileID ?? UUID(),
            authorNameSnapshot: entity.authorNameSnapshot ?? "",
            body: try CommentBody(entity.body ?? ""),
            createdAt: entity.createdAt ?? Date(),
            isRemoved: entity.isRemoved
        )
    }

    static func apply(_ comment: DiaryComment, to entity: DiaryCommentEntity) {
        entity.id = comment.id
        entity.authorProfileID = comment.authorProfileID
        entity.authorNameSnapshot = comment.authorNameSnapshot
        entity.body = comment.body.value
        entity.createdAt = comment.createdAt
        entity.isRemoved = comment.isRemoved
    }
}
