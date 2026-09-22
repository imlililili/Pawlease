import Foundation

/// Loads every member of a Circle. Separate from `LoadPetHomeUseCase`
/// (which only carries the *current* member) because Circle Settings needs
/// the full roster.
struct LoadCircleMembersUseCase: Sendable {
    let memberRepository: MemberRepository

    func execute(circleID: UUID) async throws -> [CircleMember] {
        try await memberRepository.fetchMembers(circleID: circleID)
    }
}
