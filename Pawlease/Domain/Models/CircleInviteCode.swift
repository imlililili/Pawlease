import Foundation

/// A normalized, validated Circle invite code — a lookup key only, never an
/// authorization token. Codes are generated locally from a cryptographically
/// secure random source (`SystemRandomNumberGenerator`, which Swift
/// documents as cryptographically secure where the platform provides one —
/// no external random-code service is ever called) using an unambiguous
/// uppercase alphabet that excludes `0`, `O`, `1`, and `I`.
///
/// `normalizedValue` is always `"PAW" + 8 random characters` (e.g.
/// `"PAW7K3QX9RM"`) — the literal `"PAW"` prefix is not random; it exists so
/// the formatted display (`"PAW-7K3Q-X9RM"`) reads as a recognizable brand
/// prefix. `normalizedValue` is also used as-is for `CKRecord.ID.recordName`
/// in the public database, so lookups fetch by record ID rather than
/// querying all records.
struct CircleInviteCode: Sendable, Equatable, Hashable {
    let normalizedValue: String

    static let prefix = "PAW"
    static let randomPartLength = 8
    static let alphabet: [Character] = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    /// Codes expire 48 hours after creation.
    static let validityDuration: TimeInterval = 48 * 60 * 60

    /// Validates a fully normalized value (uppercase, no whitespace, no
    /// hyphens — see `parse(rawInput:)` for turning raw user input into
    /// this). Fails for anything that isn't `"PAW"` followed by exactly
    /// `randomPartLength` characters drawn from `alphabet`.
    init?(normalizedValue: String) {
        guard normalizedValue.hasPrefix(Self.prefix) else { return nil }
        let randomPart = normalizedValue.dropFirst(Self.prefix.count)
        guard randomPart.count == Self.randomPartLength else { return nil }
        let alphabetSet = Set(Self.alphabet)
        guard randomPart.allSatisfy({ alphabetSet.contains($0) }) else { return nil }
        self.normalizedValue = normalizedValue
    }

    /// Normalizes raw user input — trims whitespace, removes hyphens,
    /// uppercases — then validates it. This is the domain validation gate:
    /// a malformed code is rejected here, before any CloudKit request is
    /// ever made.
    static func parse(rawInput: String) -> CircleInviteCode? {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutHyphens = trimmed.replacingOccurrences(of: "-", with: "")
        let normalized = withoutHyphens.uppercased()
        return CircleInviteCode(normalizedValue: normalized)
    }

    /// Generates a new random code using a cryptographically secure local
    /// random source. Never calls an external service.
    static func generateRandom() -> CircleInviteCode {
        var rng = SystemRandomNumberGenerator()
        let randomPart = String((0..<randomPartLength).compactMap { _ in alphabet.randomElement(using: &rng) })
        guard let code = CircleInviteCode(normalizedValue: prefix + randomPart) else {
            // Unreachable: `randomPart` is built exclusively from `alphabet`
            // and is always exactly `randomPartLength` characters.
            preconditionFailure("Generated invite code failed its own validation")
        }
        return code
    }

    /// A readable display form, e.g. `"PAW-7K3Q-X9RM"`. Round-trips through
    /// `parse(rawInput:)` back to the same `normalizedValue`.
    var formatted: String {
        let randomPart = String(normalizedValue.dropFirst(Self.prefix.count))
        var groups: [String] = []
        var index = randomPart.startIndex
        while index < randomPart.endIndex {
            let groupEnd = randomPart.index(index, offsetBy: 4, limitedBy: randomPart.endIndex) ?? randomPart.endIndex
            groups.append(String(randomPart[index..<groupEnd]))
            index = groupEnd
        }
        return ([Self.prefix] + groups).joined(separator: "-")
    }
}
