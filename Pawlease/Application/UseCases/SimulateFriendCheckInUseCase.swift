import Foundation

/// Debug-only demo workflow: publishes one real, local `DailyMoment` as the
/// already-seeded "Ava" member (`DemoSeed.avaProfileID`) so the Pawlease
/// portfolio demo can progress from 1/2 to 2/2 without a second physical
/// device or CloudKit. Reuses the seeded Ava rather than minting a second,
/// distinct "Ava" profile — Circle Settings shows exactly one Ava.
///
/// This never shortcuts the domain rules it's demonstrating:
/// - It never changes `CalculateDailyCareStatusUseCase.requiredContributorCount`.
/// - It never mutates a contributor counter — there isn't one; contributor
///   count and survival are always derived from persisted `DailyMoment`s
///   (see `CalculateDailyCareStatusUseCase`).
/// - It never sets the pet's activity state directly — that's derived too.
/// - It publishes through the exact same `PublishDailyMomentUseCase` used
///   by the real Post Composer, so the created post is indistinguishable,
///   in the domain model, from one published by an actual second device.
/// - It never touches CloudKit — it only calls `MemberRepository` and
///   `MomentRepository`, exactly like normal posting does.
struct SimulateFriendCheckInUseCase: Sendable {
    /// Copy specific to the simulated check-in post itself — not part of
    /// the demo friend's identity. That identity lives in `DemoSeed`, the
    /// single source of truth for every seeded Circle member (Ava
    /// included), so this workflow always publishes as the same seeded
    /// member and can never drift onto a second, unseeded "Ava" profile.
    enum CheckInContent {
        static let caption = "Ava checked in 🌼"
        static let moodEmoji = "🥳"
    }

    /// A Circle's member roster is capped — ensuring the demo friend can
    /// never grow it without bound.
    static let maxMembers = 5

    enum Result: Sendable, Equatable {
        case created(DailyMoment)
        case alreadyCheckedIn
        case unavailable(reason: String)
    }

    let memberRepository: MemberRepository
    let momentRepository: MomentRepository
    let publishDailyMomentUseCase: PublishDailyMomentUseCase
    let photoProcessingService: PhotoProcessingService
    let demoImageProvider: DemoCheckInImageProviding
    let clock: ClockProviding

    func execute(circle: FriendCircle, currentMember: CircleMember) async throws -> Result {
        // Use the Circle's own stored time zone for the day key — never the
        // device's current time zone — exactly like normal posting.
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)

        let currentMemberHasPosted = try await momentRepository.hasMemberPosted(
            circleID: circle.id, profileID: currentMember.profileID, day: today
        )
        guard currentMemberHasPosted else {
            return .unavailable(reason: "Post today's moment first, then simulate a friend's check-in.")
        }

        guard let demoFriendMember = try await ensureDemoFriendIsMember(circleID: circle.id) else {
            return .unavailable(reason: "This Circle already has the maximum number of members.")
        }

        let demoFriendHasPosted = try await momentRepository.hasMemberPosted(
            circleID: circle.id, profileID: demoFriendMember.profileID, day: today
        )
        guard !demoFriendHasPosted else {
            return .alreadyCheckedIn
        }

        guard let imageData = demoImageProvider.loadImageData() else {
            return .unavailable(reason: "The demo photo couldn't be loaded.")
        }

        let photo = try photoProcessingService.process(imageData)
        let moment = try await publishDailyMomentUseCase.execute(
            circle: circle,
            member: demoFriendMember,
            photo: photo,
            captionText: CheckInContent.caption,
            moodEmoji: CheckInContent.moodEmoji
        )
        return .created(moment)
    }

    /// Idempotent: if the seeded "Ava" member (`DemoSeed.avaProfileID`) is
    /// already in the Circle — which she always is once
    /// `SeedDemoCircleUseCase` has run — returns that existing row rather
    /// than creating a second one. Matched by profile ID only, never by
    /// display name, since a real person could legitimately share the name
    /// "Ava." Falls back to creating her (respecting the member cap) only
    /// if the Circle was somehow seeded without her. Returns `nil` only
    /// when the Circle is already at capacity.
    private func ensureDemoFriendIsMember(circleID: UUID) async throws -> CircleMember? {
        let existingMembers = try await memberRepository.fetchMembers(circleID: circleID)
        if let existing = existingMembers.first(where: { $0.profileID == DemoSeed.avaProfileID }) {
            return existing
        }
        guard existingMembers.count < Self.maxMembers else {
            return nil
        }
        return try await memberRepository.saveMember(
            CircleMember(
                id: UUID(),
                circleID: circleID,
                profileID: DemoSeed.avaProfileID,
                displayName: DemoSeed.avaDisplayName,
                avatarEmoji: DemoSeed.avaAvatarEmoji,
                joinedAt: clock.now,
                role: .member
            )
        )
    }
}
