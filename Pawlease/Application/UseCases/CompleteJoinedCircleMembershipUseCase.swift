import Foundation

/// After a `CKShare` invitation has been accepted and the shared store has
/// merged the incoming records, this finishes the join: locates the
/// specific Circle that was accepted (via the handoff — never guessed),
/// loads the current local `UserProfile`, and creates exactly one `Member`
/// row linking that profile to that Circle if one doesn't already exist.
///
/// Idempotent by construction: repeating this for the same accepted Circle
/// finds the existing Member (matched by profile ID, never by counting
/// seeded placeholder members) and returns it rather than creating a
/// duplicate. Duplicate prevention lives here, in the service/repository
/// layer — never as a Core Data unique constraint.
struct CompleteJoinedCircleMembershipUseCase: Sendable {
    static let maxMembers = 5
    static let minMembers = 2

    let circleRepository: CircleRepository
    let memberRepository: MemberRepository
    let userProfileRepository: UserProfileRepository
    let clock: ClockProviding

    @discardableResult
    func execute(handoff: AcceptedCircleHandoff) async throws -> CircleMember {
        guard let circleID = handoff.circleID else {
            // The handoff couldn't resolve which Circle was accepted — do
            // not guess by falling back to any other Circle lookup.
            throw DomainError.circleNotFound
        }
        guard let circle = try await circleRepository.fetchCircle(id: circleID) else {
            throw DomainError.circleNotFound
        }

        let profile = try await userProfileRepository.fetchOrCreateCurrentProfile()
        let existingMembers = try await memberRepository.fetchMembers(circleID: circle.id)

        if let existing = existingMembers.first(where: { $0.profileID == profile.id }) {
            return existing
        }

        guard existingMembers.count < Self.maxMembers else {
            throw DomainError.membershipFull
        }

        let member = CircleMember(
            id: UUID(),
            circleID: circle.id,
            profileID: profile.id,
            displayName: profile.displayName,
            avatarEmoji: profile.avatarEmoji,
            joinedAt: clock.now,
            role: .member
        )
        return try await memberRepository.saveMember(member)
    }
}
