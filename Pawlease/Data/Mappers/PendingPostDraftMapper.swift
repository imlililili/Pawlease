import Foundation

enum PendingPostDraftMapper {
    static func toDomain(_ entity: PendingPostDraftEntity) throws -> PendingPostDraft {
        guard let id = entity.id, let localImagePath = entity.localImagePath, let source = entity.source else {
            throw DomainError.pendingDraftCorrupted
        }
        return PendingPostDraft(
            id: id,
            caption: entity.caption,
            localImagePath: localImagePath,
            createdAt: entity.createdAt ?? Date(),
            source: source
        )
    }

    static func apply(_ draft: PendingPostDraft, to entity: PendingPostDraftEntity) {
        entity.id = draft.id
        entity.caption = draft.caption
        entity.localImagePath = draft.localImagePath
        entity.createdAt = draft.createdAt
        entity.source = draft.source
    }
}
