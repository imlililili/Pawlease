import Testing
import Foundation
@testable import Pawlease

/// Mock/in-memory-based only — never touches real Core Data or CloudKit.
struct SimulateFriendCheckInUseCaseTests {
    private func makeCircle(clock: FakeClock, timeZoneIdentifier: String = "UTC") -> FriendCircle {
        FriendCircle(id: UUID(), name: "Test Circle", timezoneIdentifier: timeZoneIdentifier, createdAt: clock.now, ownerProfileID: UUID())
    }

    private func makeUseCase(
        memberRepository: MemberRepository,
        momentRepository: MomentRepository,
        clock: ClockProviding,
        demoImageProvider: DemoCheckInImageProviding = MockDemoCheckInImageProvider()
    ) -> SimulateFriendCheckInUseCase {
        SimulateFriendCheckInUseCase(
            memberRepository: memberRepository,
            momentRepository: momentRepository,
            publishDailyMomentUseCase: PublishDailyMomentUseCase(momentRepository: momentRepository, clock: clock),
            photoProcessingService: PhotoProcessingService(),
            demoImageProvider: demoImageProvider,
            clock: clock
        )
    }

    @Test
    func currentMemberMustPostBeforeFriendSimulation() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository() // no posts at all yet
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        let result = try await useCase.execute(circle: circle, currentMember: currentMember)

        guard case .unavailable = result else {
            Issue.record("Expected .unavailable when the current member hasn't posted yet, got \(result)")
            return
        }
        #expect(memberRepo.members.isEmpty) // never even ensures the demo friend membership
        #expect(momentRepo.moments.isEmpty)
    }

    @Test
    func demoFriendUsesAProfileIDDistinctFromTheCurrentMember() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier))]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        _ = try await useCase.execute(circle: circle, currentMember: currentMember)

        #expect(DemoSeed.avaProfileID != currentMember.profileID)
        let demoFriendMember = memberRepo.members.first { $0.profileID == DemoSeed.avaProfileID }
        #expect(demoFriendMember != nil)
    }

    @Test
    func firstSimulationCreatesExactlyOneValidDailyPost() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: today)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        let result = try await useCase.execute(circle: circle, currentMember: currentMember)

        guard case .created(let moment) = result else {
            Issue.record("Expected .created, got \(result)")
            return
        }
        #expect(moment.authorProfileID == DemoSeed.avaProfileID)
        #expect(moment.caption.value == SimulateFriendCheckInUseCase.CheckInContent.caption)
        #expect(moment.moodEmoji == SimulateFriendCheckInUseCase.CheckInContent.moodEmoji)
        #expect(!moment.photo.imageData.isEmpty)
        #expect(!moment.photo.thumbnailData.isEmpty)

        let demoFriendPosts = momentRepo.moments.filter { $0.authorProfileID == DemoSeed.avaProfileID }
        #expect(demoFriendPosts.count == 1)
    }

    @Test
    func repeatedSimulationDoesNotCreateAnotherPost() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: today)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        let first = try await useCase.execute(circle: circle, currentMember: currentMember)
        let second = try await useCase.execute(circle: circle, currentMember: currentMember)

        guard case .created = first else { Issue.record("Expected first call to create a post"); return }
        guard case .alreadyCheckedIn = second else { Issue.record("Expected second call to report alreadyCheckedIn, got \(second)"); return }

        let demoFriendPosts = momentRepo.moments.filter { $0.authorProfileID == DemoSeed.avaProfileID }
        #expect(demoFriendPosts.count == 1)
        #expect(memberRepo.members.filter { $0.profileID == DemoSeed.avaProfileID }.count == 1)
    }

    @Test
    func twoDistinctContributorsProduce2Of2AndSurvived() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: today)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        _ = try await useCase.execute(circle: circle, currentMember: currentMember)

        let todaysMoments = try await momentRepo.fetchMoments(circleID: circle.id, day: today)
        let careStatus = CalculateDailyCareStatusUseCase().execute(moments: todaysMoments)

        #expect(careStatus.contributorCount == 2)
        #expect(careStatus.requiredContributorCount == 2)
        #expect(careStatus.hasSurvived)
    }

    @Test
    func twoPostsFromTheCurrentMemberStillCountAsOne() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        // The current member "posted" twice (e.g. edited their caption) —
        // still only one contributor.
        let publishUseCase = PublishDailyMomentUseCase(momentRepository: momentRepo, clock: clock)
        let photo = try MomentPhoto(imageData: Data([0xFF]), thumbnailData: Data([0xFF]))
        _ = try await publishUseCase.execute(circle: circle, member: currentMember, photo: photo, captionText: "First", moodEmoji: nil)
        _ = try await publishUseCase.execute(circle: circle, member: currentMember, photo: photo, captionText: "Second", moodEmoji: nil)

        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)
        _ = try await useCase.execute(circle: circle, currentMember: currentMember)

        let todaysMoments = try await momentRepo.fetchMoments(circleID: circle.id, day: today)
        let careStatus = CalculateDailyCareStatusUseCase().execute(moments: todaysMoments)

        // Current member (one contributor, despite two posts) + Ava = 2.
        #expect(careStatus.contributorCount == 2)
        #expect(careStatus.hasSurvived)
    }

    @Test
    func circleTimeZoneDeterminesTheDemoPostDayKey() async throws {
        // Chosen so UTC and Tokyo land on different calendar days for the
        // same instant.
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15, hour: 23, timeZoneIdentifier: "UTC"))
        let circle = makeCircle(clock: clock, timeZoneIdentifier: "Asia/Tokyo")
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let circleDay = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: circleDay)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        let result = try await useCase.execute(circle: circle, currentMember: currentMember)

        guard case .created(let moment) = result else { Issue.record("Expected .created"); return }
        #expect(moment.day == circleDay)
        // Sanity: the Circle's timezone really does put this instant on a
        // different calendar day than UTC would.
        let utcDay = CircleDay(date: clock.now, timeZoneIdentifier: "UTC")
        #expect(moment.day != utcDay)
    }

    @Test
    func demoMemberCreationIsIdempotent() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: today)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        _ = try await useCase.execute(circle: circle, currentMember: currentMember)
        // Simulate a relaunch: Ava already checked in today, so the second
        // call takes the `.alreadyCheckedIn` path — membership must still
        // not duplicate.
        _ = try await useCase.execute(circle: circle, currentMember: currentMember)

        let demoFriendMembers = memberRepo.members.filter { $0.profileID == DemoSeed.avaProfileID }
        #expect(demoFriendMembers.count == 1)
        #expect(demoFriendMembers.first?.displayName == DemoSeed.avaDisplayName)
        #expect(demoFriendMembers.first?.avatarEmoji == DemoSeed.avaAvatarEmoji)
    }

    /// Regression test for the Circle Settings identity-mismatch bug: a
    /// previous version minted a brand-new, unseeded profile ID for "Ava"
    /// instead of reusing the one `SeedDemoCircleUseCase` already created —
    /// which showed up as a fourth, duplicate-looking "Ava" row. Matched by
    /// profile ID only, never by display name.
    @Test
    func seededAvaIsReused() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        // The seeded Ava already exists — a distinct `id` and `joinedAt`
        // from anything this Use Case would generate, so reuse vs.
        // replacement is unambiguous.
        let seededAvaID = UUID()
        let seededAvaJoinedAt = Date(timeIntervalSince1970: 500)
        memberRepo.members = [CircleMember(
            id: seededAvaID, circleID: circle.id, profileID: DemoSeed.avaProfileID,
            displayName: DemoSeed.avaDisplayName, avatarEmoji: DemoSeed.avaAvatarEmoji,
            joinedAt: seededAvaJoinedAt, role: .member
        )]
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: today)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        let result = try await useCase.execute(circle: circle, currentMember: currentMember)

        guard case .created(let moment) = result else { Issue.record("Expected .created, got \(result)"); return }
        #expect(moment.authorProfileID == DemoSeed.avaProfileID)

        // Still exactly one Ava row, and it's the literal pre-existing one
        // (same `id`/`joinedAt`) — proving reuse, not a replacement.
        let avaMembers = memberRepo.members.filter { $0.profileID == DemoSeed.avaProfileID }
        #expect(avaMembers.count == 1)
        #expect(avaMembers.first?.id == seededAvaID)
        #expect(avaMembers.first?.joinedAt == seededAvaJoinedAt)
    }

    /// Regression test proving the fix doesn't grow the roster: with the
    /// realistic seeded three-member Circle (You, Ava, Noah) already
    /// present, simulating Ava's check-in must never create a fourth
    /// member.
    @Test
    func noFourthMemberIsCreated() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(
            id: UUID(), circleID: circle.id, profileID: DemoSeed.currentProfileID,
            displayName: DemoSeed.memberNames[0], avatarEmoji: DemoSeed.memberEmojis[0], joinedAt: clock.now, role: .owner
        )

        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = (0..<3).map { index in
            CircleMember(
                id: UUID(), circleID: circle.id, profileID: DemoSeed.memberProfileIDs[index],
                displayName: DemoSeed.memberNames[index], avatarEmoji: DemoSeed.memberEmojis[index],
                joinedAt: clock.now, role: index == 0 ? .owner : .member
            )
        }
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: today)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        let result = try await useCase.execute(circle: circle, currentMember: currentMember)

        guard case .created = result else { Issue.record("Expected .created, got \(result)"); return }
        let members = try await memberRepo.fetchMembers(circleID: circle.id)
        #expect(members.count == 3)
        #expect(Set(members.map(\.profileID)) == Set(DemoSeed.memberProfileIDs))
    }

    @Test
    func sixthDistinctMemberIsRejected() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        // The Circle already has 5 distinct members (current member + 4
        // others) — at the cap before the demo friend is even considered.
        memberRepo.members = [currentMember] + (0..<4).map { _ in TestFactories.member(circleID: circle.id, profileID: UUID()) }
        let momentRepo = InMemoryMomentRepository()
        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        momentRepo.moments = [try TestFactories.moment(circleID: circle.id, authorID: currentMember.profileID, day: today)]
        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        let result = try await useCase.execute(circle: circle, currentMember: currentMember)

        guard case .unavailable = result else {
            Issue.record("Expected .unavailable when the Circle is already at its member cap, got \(result)")
            return
        }
        #expect(memberRepo.members.count == 5) // no sixth member was ever created
        #expect(momentRepo.moments.filter { $0.authorProfileID == DemoSeed.avaProfileID }.isEmpty)
    }

    @Test
    func failedLocalPersistenceDoesNotReportSuccess() async throws {
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let circle = makeCircle(clock: clock)
        let currentMember = CircleMember(id: UUID(), circleID: circle.id, profileID: UUID(), displayName: "You", avatarEmoji: "🦊", joinedAt: clock.now, role: .owner)

        let memberRepo = InMemoryMemberRepository()
        let momentRepo = MockMomentRepository()
        momentRepo.hasMemberPostedHandler = { _, profileID, _ in
            profileID == currentMember.profileID // current member posted; demo friend hasn't
        }
        struct StubPersistenceError: Error {}
        momentRepo.saveMomentError = StubPersistenceError()

        let useCase = makeUseCase(memberRepository: memberRepo, momentRepository: momentRepo, clock: clock)

        await #expect(throws: StubPersistenceError.self) {
            _ = try await useCase.execute(circle: circle, currentMember: currentMember)
        }
    }
}
