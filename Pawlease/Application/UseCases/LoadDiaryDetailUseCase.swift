import Foundation

/// Assembles everything the Diary Entry Detail screen needs: the entry
/// itself, its comments in chronological order, and every reaction on the
/// entry and its comments. Loads an entry regardless of expiry/deletion
/// state — access to an expired entry is already gated upstream (the
/// active feed excludes it; only the author's Archive links to it) — so
/// this never re-derives or enforces that here.
struct LoadDiaryDetailUseCase: Sendable {
    struct Result: Sendable, Equatable {
        let entry: DiaryEntry
        let comments: [DiaryComment]
        let entryReactions: [DiaryReaction]
        let commentReactions: [DiaryCommentReaction]
    }

    let diaryEntryRepository: DiaryEntryRepository
    let diaryCommentRepository: DiaryCommentRepository
    let diaryReactionRepository: DiaryReactionRepository
    let diaryCommentReactionRepository: DiaryCommentReactionRepository

    func execute(entryID: UUID) async throws -> Result {
        guard let entry = try await diaryEntryRepository.fetchEntry(entryID: entryID) else {
            throw DomainError.diaryEntryNotFound
        }

        let comments = try await diaryCommentRepository
            .fetchComments(entryID: entryID)
            .sorted { $0.createdAt < $1.createdAt }

        let entryReactions = try await diaryReactionRepository.fetchReactions(entryID: entryID)

        var commentReactions: [DiaryCommentReaction] = []
        for comment in comments {
            commentReactions += try await diaryCommentReactionRepository.fetchReactions(commentID: comment.id)
        }

        return Result(
            entry: entry,
            comments: comments,
            entryReactions: entryReactions,
            commentReactions: commentReactions
        )
    }
}
