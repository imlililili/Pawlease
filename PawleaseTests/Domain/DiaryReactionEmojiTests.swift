import Testing
@testable import Pawlease

struct DiaryReactionEmojiTests {
    @Test
    func validSingleEmojiIsAccepted() throws {
        let heart = try DiaryReactionEmoji("❤️")
        #expect(heart.value == "❤️")

        let familyZWJSequence = try DiaryReactionEmoji("👨‍👩‍👧‍👦")
        #expect(familyZWJSequence.value == "👨‍👩‍👧‍👦")

        let flag = try DiaryReactionEmoji("🇯🇵")
        #expect(flag.value == "🇯🇵")
    }

    @Test
    func invalidMultiCharacterInputIsRejected() {
        #expect(throws: DomainValidationError.invalidDiaryReactionEmoji) {
            _ = try DiaryReactionEmoji("😀😀")
        }
        #expect(throws: DomainValidationError.invalidDiaryReactionEmoji) {
            _ = try DiaryReactionEmoji("great!")
        }
    }

    @Test
    func nonEmojiCharacterIsRejected() {
        #expect(throws: DomainValidationError.invalidDiaryReactionEmoji) {
            _ = try DiaryReactionEmoji("a")
        }
        #expect(throws: DomainValidationError.invalidDiaryReactionEmoji) {
            _ = try DiaryReactionEmoji("3")
        }
        #expect(throws: DomainValidationError.invalidDiaryReactionEmoji) {
            _ = try DiaryReactionEmoji("#")
        }
    }

    @Test
    func emptyOrWhitespaceInputIsRejected() {
        #expect(throws: DomainValidationError.invalidDiaryReactionEmoji) {
            _ = try DiaryReactionEmoji("")
        }
        #expect(throws: DomainValidationError.invalidDiaryReactionEmoji) {
            _ = try DiaryReactionEmoji("   ")
        }
    }
}
