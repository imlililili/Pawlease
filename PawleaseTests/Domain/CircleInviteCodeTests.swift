import Testing
@testable import Pawlease

struct CircleInviteCodeTests {
    @Test
    func generatedCodeUsesThePermittedAlphabetAndExpectedLength() {
        let code = CircleInviteCode.generateRandom()

        #expect(code.normalizedValue.hasPrefix("PAW"))
        let randomPart = code.normalizedValue.dropFirst(3)
        #expect(randomPart.count == 8)
        let alphabet = Set(CircleInviteCode.alphabet)
        #expect(randomPart.allSatisfy { alphabet.contains($0) })
        // The excluded, ambiguous characters must never appear.
        #expect(!randomPart.contains("0"))
        #expect(!randomPart.contains("O"))
        #expect(!randomPart.contains("1"))
        #expect(!randomPart.contains("I"))
    }

    @Test
    func formattingAndNormalizationRoundTrip() throws {
        let code = CircleInviteCode.generateRandom()

        let formatted = code.formatted
        #expect(formatted.hasPrefix("PAW-"))

        let reparsed = try #require(CircleInviteCode.parse(rawInput: formatted))
        #expect(reparsed == code)

        // Lowercase, extra whitespace, and stray hyphens all normalize the
        // same way.
        let messyInput = "  \(formatted.lowercased())  "
        let reparsedMessy = try #require(CircleInviteCode.parse(rawInput: messyInput))
        #expect(reparsedMessy == code)
    }

    @Test
    func malformedCodeIsRejectedBeforeAnyRepositoryAccess() {
        #expect(CircleInviteCode.parse(rawInput: "") == nil)
        #expect(CircleInviteCode.parse(rawInput: "PAW-1234") == nil) // too short, and contains excluded '1'
        #expect(CircleInviteCode.parse(rawInput: "XYZ-7K3Q-X9RM") == nil) // wrong prefix
        #expect(CircleInviteCode.parse(rawInput: "PAW-7K3Q-X9RMEXTRA") == nil) // too long
        #expect(CircleInviteCode.parse(rawInput: "PAW-7K3O-X9RM") == nil) // contains excluded 'O'
    }

    @Test
    func twoGeneratedCodesAreDifferent() {
        let first = CircleInviteCode.generateRandom()
        let second = CircleInviteCode.generateRandom()

        #expect(first != second)
    }
}
