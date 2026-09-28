import Foundation
@testable import Pawlease

final class InMemoryDiaryEntryRepository: DiaryEntryRepository, @unchecked Sendable {
    var entries: [DiaryEntry] = []

    func fetchEntries(circleID: UUID) async throws -> [DiaryEntry] {
        entries.filter { $0.circleID == circleID }
    }

    func fetchEntry(entryID: UUID) async throws -> DiaryEntry? {
        entries.first { $0.id == entryID }
    }

    @discardableResult
    func saveEntry(_ entry: DiaryEntry) async throws -> DiaryEntry {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        return entry
    }

    func softDeleteEntry(entryID: UUID, requestingProfileID: UUID, deletedAt: Date) async throws {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else {
            throw DomainError.diaryEntryNotFound
        }
        guard entries[index].authorProfileID == requestingProfileID else {
            throw DomainError.notDiaryEntryAuthor
        }
        let existing = entries[index]
        entries[index] = DiaryEntry(
            id: existing.id, circleID: existing.circleID, authorProfileID: existing.authorProfileID,
            authorNameSnapshot: existing.authorNameSnapshot, authorAvatarSnapshot: existing.authorAvatarSnapshot,
            body: existing.body, visibilityDuration: existing.visibilityDuration, createdAt: existing.createdAt,
            expiresAt: existing.expiresAt, isDeleted: true, deletedAt: deletedAt
        )
    }
}

final class InMemoryDiaryCommentRepository: DiaryCommentRepository, @unchecked Sendable {
    var comments: [DiaryComment] = []

    func fetchComments(entryID: UUID) async throws -> [DiaryComment] {
        comments.filter { $0.entryID == entryID }
    }

    func fetchComment(commentID: UUID) async throws -> DiaryComment? {
        comments.first { $0.id == commentID }
    }

    @discardableResult
    func saveComment(_ comment: DiaryComment) async throws -> DiaryComment {
        if let index = comments.firstIndex(where: { $0.id == comment.id }) {
            comments[index] = comment
        } else {
            comments.append(comment)
        }
        return comment
    }

    func softDeleteComment(commentID: UUID, requestingMemberID: UUID) async throws {
        guard let index = comments.firstIndex(where: { $0.id == commentID }) else {
            throw DomainError.diaryCommentNotFound
        }
        guard comments[index].authorProfileID == requestingMemberID else {
            throw DomainError.notCommentAuthor
        }
        let existing = comments[index]
        comments[index] = DiaryComment(
            id: existing.id, entryID: existing.entryID, authorProfileID: existing.authorProfileID,
            authorNameSnapshot: existing.authorNameSnapshot, body: existing.body,
            createdAt: existing.createdAt, isRemoved: true
        )
    }
}

final class InMemoryDiaryReactionRepository: DiaryReactionRepository, @unchecked Sendable {
    var reactions: [DiaryReaction] = []

    func fetchReactions(entryID: UUID) async throws -> [DiaryReaction] {
        reactions.filter { $0.entryID == entryID }
    }

    func reaction(entryID: UUID, memberProfileID: UUID) async throws -> DiaryReaction? {
        reactions.first { $0.entryID == entryID && $0.memberProfileID == memberProfileID }
    }

    func saveReaction(_ reaction: DiaryReaction) async throws {
        if let index = reactions.firstIndex(where: { $0.entryID == reaction.entryID && $0.memberProfileID == reaction.memberProfileID }) {
            reactions[index] = reaction
        } else {
            reactions.append(reaction)
        }
    }

    func removeReaction(entryID: UUID, memberProfileID: UUID) async throws {
        reactions.removeAll { $0.entryID == entryID && $0.memberProfileID == memberProfileID }
    }
}

final class InMemoryDiaryCommentReactionRepository: DiaryCommentReactionRepository, @unchecked Sendable {
    var reactions: [DiaryCommentReaction] = []

    func fetchReactions(commentID: UUID) async throws -> [DiaryCommentReaction] {
        reactions.filter { $0.commentID == commentID }
    }

    func reaction(commentID: UUID, memberProfileID: UUID) async throws -> DiaryCommentReaction? {
        reactions.first { $0.commentID == commentID && $0.memberProfileID == memberProfileID }
    }

    func saveReaction(_ reaction: DiaryCommentReaction) async throws {
        if let index = reactions.firstIndex(where: { $0.commentID == reaction.commentID && $0.memberProfileID == reaction.memberProfileID }) {
            reactions[index] = reaction
        } else {
            reactions.append(reaction)
        }
    }

    func removeReaction(commentID: UUID, memberProfileID: UUID) async throws {
        reactions.removeAll { $0.commentID == commentID && $0.memberProfileID == memberProfileID }
    }
}
