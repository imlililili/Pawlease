import Testing
@testable import Pawlease

struct CommentBodyTests {
    @Test func rejectsCommentsLongerThan60Characters() {
        let tooLong = String(repeating: "a", count: 61)
        #expect(throws: DomainValidationError.commentTooLong) {
            _ = try CommentBody(tooLong)
        }
    }

    @Test func acceptsExactly60Characters() throws {
        let exact = String(repeating: "a", count: 60)
        let body = try CommentBody(exact)
        #expect(body.value.count == 60)
    }

    @Test func rejectsWhitespaceOnlyComment() {
        #expect(throws: DomainValidationError.commentEmpty) {
            _ = try CommentBody("   ")
        }
    }
}
