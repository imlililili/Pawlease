import Foundation

/// Deterministic identifiers for the local demo Circle so the seeded data,
/// the "current member" simulation, and tests all agree on the same IDs.
enum DemoSeed {
    static let circleID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let memberProfileIDs: [UUID] = [
        UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
        UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!,
        UUID(uuidString: "00000000-0000-0000-0000-0000000000A3")!
    ]
    static let memberNames = ["You", "Ava", "Noah"]
    static let memberEmojis = ["🦊", "🐼", "🐨"]

    /// The profile ID Phase 1 treats as "the current member" on this device.
    static let currentProfileID = memberProfileIDs[0]
}

/// Seeds one local demo Circle with three members and one pet, if none
/// exists yet. Idempotent — safe to call on every app launch.
struct SeedDemoCircleUseCase: Sendable {
    let circleRepository: CircleRepository
    let memberRepository: MemberRepository
    let petRepository: PetRepository
    let clock: ClockProviding

    struct SeedResult: Sendable, Equatable {
        let circle: FriendCircle
        let members: [CircleMember]
        let pet: SharedPet
    }

    func execute() async throws -> SeedResult {
        if let existingCircle = try await circleRepository.fetchDefaultCircle(),
           let existingPet = try await petRepository.fetchPet(circleID: existingCircle.id) {
            let members = try await memberRepository.fetchMembers(circleID: existingCircle.id)
            return SeedResult(circle: existingCircle, members: members, pet: existingPet)
        }

        let circle = FriendCircle(
            id: DemoSeed.circleID,
            name: "The Pack",
            timezoneIdentifier: TimeZone.current.identifier,
            createdAt: clock.now,
            ownerProfileID: DemoSeed.memberProfileIDs[0]
        )
        let savedCircle = try await circleRepository.saveCircle(circle)

        var savedMembers: [CircleMember] = []
        for (index, profileID) in DemoSeed.memberProfileIDs.enumerated() {
            let member = CircleMember(
                id: UUID(),
                circleID: savedCircle.id,
                profileID: profileID,
                displayName: DemoSeed.memberNames[index],
                avatarEmoji: DemoSeed.memberEmojis[index],
                joinedAt: clock.now,
                role: index == 0 ? .owner : .member
            )
            savedMembers.append(try await memberRepository.saveMember(member))
        }

        let pet = SharedPet(
            id: UUID(),
            circleID: savedCircle.id,
            name: "Mochi",
            speciesKey: "fox",
            stage: .hatchling,
            growthPoints: 0,
            createdAt: clock.now
        )
        let savedPet = try await petRepository.savePet(pet)

        return SeedResult(circle: savedCircle, members: savedMembers, pet: savedPet)
    }
}
