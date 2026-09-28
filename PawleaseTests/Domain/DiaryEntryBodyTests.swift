import Testing
@testable import Pawlease

struct DiaryEntryBodyTests {
    @Test
    func whitespaceOnlyDiaryTextIsRejected() {
        #expect(throws: DomainValidationError.diaryBodyEmpty) {
            _ = try DiaryEntryBody("   \n\t  ")
        }
    }

    @Test
    func exactly500CharactersAreAccepted() throws {
        let exact = String(repeating: "a", count: 500)
        let body = try DiaryEntryBody(exact)
        #expect(body.value.count == 500)
    }

    @Test
    func moreThan500CharactersAreRejected() {
        let tooLong = String(repeating: "a", count: 501)
        #expect(throws: DomainValidationError.diaryBodyTooLong) {
            _ = try DiaryEntryBody(tooLong)
        }
    }
}
