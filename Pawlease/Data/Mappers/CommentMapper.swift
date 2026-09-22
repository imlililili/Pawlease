import Foundation

enum CommentMapper {
    static func toDomain(_ entity: CommentEntity) throws -> MomentComment {
        MomentComment(
            id: entity.id ?? UUID(),
            momentID: entity.dailyPost?.id ?? UUID(),
            authorProfileID: entity.authorProfileID ?? UUID(),
            authorNameSnapshot: entity.authorNameSnapshot ?? "",
            body: try CommentBody(entity.body ?? ""),
            createdAt: entity.createdAt ?? Date(),
            isRemoved: entity.isRemoved
        )
    }

    static func apply(_ comment: MomentComment, to entity: CommentEntity) {
        entity.id = comment.id
        entity.authorProfileID = comment.authorProfileID
        entity.authorNameSnapshot = comment.authorNameSnapshot
        entity.body = comment.body.value
        entity.createdAt = comment.createdAt
        entity.isRemoved = comment.isRemoved
    }
}
