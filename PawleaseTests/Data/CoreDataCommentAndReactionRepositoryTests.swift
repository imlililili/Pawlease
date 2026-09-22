import Testing
import Foundation
@testable import Pawlease

/// Integration tests against the real, in-memory Core Data stack — not
/// mock-based, and not counted toward the minimum mock-based unit test
/// requirement. These prove the schema, mappers, and repositories actually
/// work together end to end.
struct CoreDataCommentAndReactionRepositoryTests {
    @Test
    func inMemoryStoreSavesFetchesAndSoftDeletesAComment() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let momentRepo = CoreDataMomentRepository(container: persistence.container)
        let commentRepo = CoreDataCommentRepository(container: persistence.container)

        let circle = FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        let savedCircle = try await circleRepo.saveCircle(circle)

        let moment = DailyMoment(
            id: UUID(), circleID: savedCircle.id, authorProfileID: UUID(), authorNameSnapshot: "Ava",
            day: CircleDay(value: "2026-03-15"), caption: try MomentCaption("Hello"), moodEmoji: nil,
            photo: try MomentPhoto(imageData: Data([0xFF]), thumbnailData: Data([0xFF])), createdAt: Date()
        )
        let savedMoment = try await momentRepo.saveMoment(moment)

        let authorID = UUID()
        let comment = MomentComment(
            id: UUID(), momentID: savedMoment.id, authorProfileID: authorID, authorNameSnapshot: "Noah",
            body: try CommentBody("Cute!"), createdAt: Date(), isRemoved: false
        )
        let saved = try await commentRepo.saveComment(comment)
        #expect(saved.body.value == "Cute!")

        let fetched = try await commentRepo.fetchComments(momentID: savedMoment.id)
        #expect(fetched.count == 1)
        #expect(fetched.first?.isRemoved == false)

        try await commentRepo.softDeleteComment(commentID: saved.id, requestingMemberID: authorID)

        let afterDelete = try await commentRepo.fetchComment(commentID: saved.id)
        #expect(afterDelete?.isRemoved == true)
        #expect(afterDelete?.id == saved.id)
        #expect(afterDelete?.authorProfileID == authorID)
    }

    @Test
    func inMemoryStoreEnforcesOneMomentReactionPerMember() async throws {
        let persistence = PersistenceController(mode: .inMemory)
        let circleRepo = CoreDataCircleRepository(container: persistence.container)
        let momentRepo = CoreDataMomentRepository(container: persistence.container)
        let reactionRepo = CoreDataMomentReactionRepository(container: persistence.container)

        let circle = FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID())
        let savedCircle = try await circleRepo.saveCircle(circle)

        let moment = DailyMoment(
            id: UUID(), circleID: savedCircle.id, authorProfileID: UUID(), authorNameSnapshot: "Ava",
            day: CircleDay(value: "2026-03-15"), caption: try MomentCaption("Hello"), moodEmoji: nil,
            photo: try MomentPhoto(imageData: Data([0xFF]), thumbnailData: Data([0xFF])), createdAt: Date()
        )
        let savedMoment = try await momentRepo.saveMoment(moment)
        let memberID = UUID()

        try await reactionRepo.saveReaction(MomentReaction(id: UUID(), momentID: savedMoment.id, memberProfileID: memberID, emoji: .heart, createdAt: Date()))
        try await reactionRepo.saveReaction(MomentReaction(id: UUID(), momentID: savedMoment.id, memberProfileID: memberID, emoji: .fire, createdAt: Date()))

        let reactions = try await reactionRepo.fetchReactions(momentID: savedMoment.id)
        #expect(reactions.count == 1)
        #expect(reactions.first?.emoji == .fire)
    }
}
