import Testing
@testable import Pawlease

struct PostComposerViewStateTests {
    @Test func emptyCaptionIsValidBecauseAMomentOnlyRequiresAPhoto() {
        let state = PostComposerViewState(captionText: "", limit: MomentCaption.maxLength)

        #expect(state.isCaptionValid)
        #expect(state.characterCountLabel == "0/60")
    }

    @Test func captionBeyondTheDomainLimitIsInvalid() {
        let state = PostComposerViewState(
            captionText: String(repeating: "a", count: MomentCaption.maxLength + 1),
            limit: MomentCaption.maxLength
        )

        #expect(!state.isCaptionValid)
        #expect(state.characterCountLabel == "61/60")
    }
}
