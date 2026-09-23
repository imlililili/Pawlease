import Testing
@testable import Pawlease

struct ShareCaptionValidationTests {
    @Test
    func aSixtyCharacterCaptionIsAccepted() {
        let caption = String(repeating: "a", count: 60)

        switch ShareCaptionValidation.validate(caption) {
        case .success(let validated):
            #expect(validated == caption)
        case .failure:
            Issue.record("Expected a 60-character caption to be accepted")
        }
    }

    @Test
    func aSixtyOneCharacterCaptionIsRejected() {
        let caption = String(repeating: "a", count: 61)

        switch ShareCaptionValidation.validate(caption) {
        case .failure(.tooLong):
            break
        case .success:
            Issue.record("Expected a 61-character caption to be rejected")
        }
    }

    @Test
    func anEmptyOrWhitespaceOnlyCaptionNormalizesToNil() {
        switch ShareCaptionValidation.validate("   \n  ") {
        case .success(let validated):
            #expect(validated == nil)
        case .failure:
            Issue.record("Expected a whitespace-only caption to be valid and normalize to nil")
        }
    }
}
