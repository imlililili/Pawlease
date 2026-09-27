import Testing
@testable import Pawlease

struct MomentCaptionTests {
    @Test func rejectsCaptionsLongerThan60Characters() {
        let tooLong = String(repeating: "a", count: 61)
        #expect(throws: DomainValidationError.captionTooLong) {
            _ = try MomentCaption(tooLong)
        }
    }

    @Test func acceptsExactly60Characters() throws {
        let exact = String(repeating: "a", count: 60)
        let caption = try MomentCaption(exact)
        #expect(caption.value.count == 60)
    }

    @Test func emptyCaptionIsAcceptedAndNormalized() throws {
        let caption = try MomentCaption("   ")
        #expect(caption.value.isEmpty)
    }
}
