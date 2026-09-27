import Foundation

/// Debug-only, narrowly-scoped one-time cleanup for exactly one known-bad
/// legacy profile ID: an earlier version of `SimulateFriendCheckInUseCase`
/// minted a brand-new UUID for "Ava" instead of reusing the already-seeded
/// member (`DemoSeed.avaProfileID`), which could have persisted a fourth
/// Circle member — and a demo `DailyMoment` authored by her — under that
/// legacy ID.
///
/// This is intentionally as narrow as possible:
/// - It matches on this **one exact, hardcoded profile ID** — never a
///   display name, never a wildcard. A real "Ava" with any other profile
///   ID (a real CloudKit participant, or any other seeded/joined member)
///   is never touched, and neither is any other member for any other
///   reason.
/// - It only ever deletes the Member row and `DailyMoment`(s) authored by
///   that exact legacy ID — nothing else in the Circle is affected. Those
///   records are explicitly known to be Debug-only demo data (that ID was
///   never anything but this bug), so deleting them doesn't touch any real
///   memory.
/// - The Use Case itself has no CloudKit involvement and is safe to
///   compile unconditionally; callers are expected to invoke it only from
///   Debug-only code paths (see `PetHomeViewModel.performRefresh()`),
///   matching this app's existing "Use Cases stay compiled, call sites are
///   Debug-gated" convention for demo-only functionality.
struct CleanUpLegacyDemoFriendUseCase: Sendable {
    /// The exact profile ID a previous `SimulateFriendCheckInUseCase`
    /// mistakenly minted for "Ava" before it was fixed to reuse
    /// `DemoSeed.avaProfileID`. Never reused for anything else.
    static let legacyAvaProfileID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

    let memberRepository: MemberRepository
    let momentRepository: MomentRepository

    func execute(circleID: UUID) async throws {
        try await momentRepository.deleteMoments(circleID: circleID, authorProfileID: Self.legacyAvaProfileID)
        try await memberRepository.deleteMember(circleID: circleID, profileID: Self.legacyAvaProfileID)
    }
}
