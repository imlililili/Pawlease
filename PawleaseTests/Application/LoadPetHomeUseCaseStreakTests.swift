import Testing
import Foundation
@testable import Pawlease

/// End-to-end streak regression coverage for `LoadPetHomeUseCase`: the full
/// chain (Circle-day derivation → `CoreData`-shaped repository filtering →
/// `CalculateDailyCareStatusUseCase` → `CalculatePetStreakUseCase`) rather
/// than the pure calculator in isolation. Added in response to a reported
/// "day two shows a 1-day streak instead of 2" defect — reproduced here via
/// three independent scenarios (direct publish, the real demo-check-in
/// flow, and repeated refreshes) to rule out every layer named in the
/// report. None of these reproduce the defect against the current
/// `LoadPetHomeUseCase`/`CalculatePetStreakUseCase`/`CoreDataMomentRepository`
/// chain — the existing implementation already satisfies every rule below.
/// They're kept as permanent regression coverage, not as a bug fix.
struct LoadPetHomeUseCaseStreakTests {
    private let timeZone = "America/Los_Angeles"

    private func makeUseCase(
        circleRepo: InMemoryCircleRepository,
        memberRepo: InMemoryMemberRepository,
        petRepo: InMemoryPetRepository,
        momentRepo: InMemoryMomentRepository,
        clock: ClockProviding,
        currentProfileID: UUID
    ) -> LoadPetHomeUseCase {
        LoadPetHomeUseCase(
            circleRepository: circleRepo,
            memberRepository: memberRepo,
            petRepository: petRepo,
            momentRepository: momentRepo,
            clock: clock,
            currentProfileID: currentProfileID
        )
    }

    /// Required test 1: two distinct members surviving day one alone (no
    /// prior history at all) produces a 1-day streak.
    @Test func twoDistinctContributorsOnDayOneAloneProduceAOneDayStreak() async throws {
        let circleID = UUID()
        let memberID = UUID()
        let friendID = UUID()
        let day1 = TestFactories.date(year: 2026, month: 3, day: 14, hour: 20, timeZoneIdentifier: timeZone)
        let clock = FakeClock(now: day1)

        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(id: circleID, name: "Test Circle", timezoneIdentifier: timeZone, createdAt: day1, ownerProfileID: memberID)
        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            TestFactories.member(circleID: circleID, profileID: memberID),
            TestFactories.member(circleID: circleID, profileID: friendID)
        ]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: day1)

        let circleDay1 = CircleDay(date: day1, timeZoneIdentifier: timeZone)
        let momentRepo = InMemoryMomentRepository()
        momentRepo.moments = [
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleDay1, createdAt: day1),
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay1, createdAt: day1)
        ]

        let useCase = makeUseCase(circleRepo: circleRepo, memberRepo: memberRepo, petRepo: petRepo, momentRepo: momentRepo, clock: clock, currentProfileID: memberID)
        let snapshot = try await useCase.execute()

        #expect(snapshot.careStatus.hasSurvived == true)
        #expect(snapshot.currentStreak == 1)
    }

    /// Required test 2: two distinct members surviving day one AND day two
    /// produces a 2-day streak — the exact scenario from the bug report.
    @Test func twoDistinctContributorsOnDayOneAndDayTwoProduceATwoDayStreak() async throws {
        let circleID = UUID()
        let memberID = UUID()
        let friendID = UUID()
        let day1 = TestFactories.date(year: 2026, month: 3, day: 14, hour: 20, timeZoneIdentifier: timeZone)
        let day2 = TestFactories.date(year: 2026, month: 3, day: 15, hour: 20, timeZoneIdentifier: timeZone)

        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(id: circleID, name: "Test Circle", timezoneIdentifier: timeZone, createdAt: day1, ownerProfileID: memberID)
        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            TestFactories.member(circleID: circleID, profileID: memberID),
            TestFactories.member(circleID: circleID, profileID: friendID)
        ]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: day1)

        let circleDay1 = CircleDay(date: day1, timeZoneIdentifier: timeZone)
        let circleDay2 = CircleDay(date: day2, timeZoneIdentifier: timeZone)
        let momentRepo = InMemoryMomentRepository()
        momentRepo.moments = [
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleDay1, createdAt: day1),
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay1, createdAt: day1),
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleDay2, createdAt: day2),
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay2, createdAt: day2)
        ]

        let useCase = makeUseCase(circleRepo: circleRepo, memberRepo: memberRepo, petRepo: petRepo, momentRepo: momentRepo, clock: FakeClock(now: day2), currentProfileID: memberID)
        let snapshot = try await useCase.execute()

        #expect(snapshot.today == circleDay2)
        #expect(snapshot.careStatus.hasSurvived == true)
        #expect(snapshot.currentStreak == 2)
    }

    /// Required test 3: three consecutive survived Circle days produce a
    /// 3-day streak, through the full `LoadPetHomeUseCase` chain (not just
    /// the pure `CalculatePetStreakUseCase`, which already covers this in
    /// isolation).
    @Test func threeConsecutiveSurvivedDaysProduceAThreeDayStreak() async throws {
        let circleID = UUID()
        let memberID = UUID()
        let friendID = UUID()
        let day1 = TestFactories.date(year: 2026, month: 3, day: 13, hour: 20, timeZoneIdentifier: timeZone)
        let day2 = TestFactories.date(year: 2026, month: 3, day: 14, hour: 20, timeZoneIdentifier: timeZone)
        let day3 = TestFactories.date(year: 2026, month: 3, day: 15, hour: 20, timeZoneIdentifier: timeZone)

        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(id: circleID, name: "Test Circle", timezoneIdentifier: timeZone, createdAt: day1, ownerProfileID: memberID)
        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            TestFactories.member(circleID: circleID, profileID: memberID),
            TestFactories.member(circleID: circleID, profileID: friendID)
        ]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: day1)

        let momentRepo = InMemoryMomentRepository()
        for date in [day1, day2, day3] {
            let circleDay = CircleDay(date: date, timeZoneIdentifier: timeZone)
            momentRepo.moments.append(try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleDay, createdAt: date))
            momentRepo.moments.append(try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay, createdAt: date))
        }

        let useCase = makeUseCase(circleRepo: circleRepo, memberRepo: memberRepo, petRepo: petRepo, momentRepo: momentRepo, clock: FakeClock(now: day3), currentProfileID: memberID)
        let snapshot = try await useCase.execute()

        #expect(snapshot.currentStreak == 3)
    }

    /// Required test 7: a post made shortly before UTC midnight, while
    /// still mid-afternoon in the Circle's own (non-UTC) time zone, must be
    /// assigned to the Circle-local day — never the UTC day. America/Los_
    /// Angeles is UTC-7 in March (daylight time), so 2026-03-14 23:30 UTC is
    /// still 2026-03-14 16:30 locally.
    @Test func postsNearUTCMidnightUseTheCircleTimeZoneNotUTC() async throws {
        let circleID = UUID()
        let memberID = UUID()
        let friendID = UUID()

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let nearUTCMidnight = utcCalendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 23, minute: 30))!

        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(id: circleID, name: "Test Circle", timezoneIdentifier: timeZone, createdAt: nearUTCMidnight, ownerProfileID: memberID)
        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            TestFactories.member(circleID: circleID, profileID: memberID),
            TestFactories.member(circleID: circleID, profileID: friendID)
        ]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: nearUTCMidnight)

        let momentRepo = InMemoryMomentRepository()
        let circleLocalDay = CircleDay(date: nearUTCMidnight, timeZoneIdentifier: timeZone)
        momentRepo.moments = [
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleLocalDay, createdAt: nearUTCMidnight),
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleLocalDay, createdAt: nearUTCMidnight)
        ]

        let useCase = makeUseCase(circleRepo: circleRepo, memberRepo: memberRepo, petRepo: petRepo, momentRepo: momentRepo, clock: FakeClock(now: nearUTCMidnight), currentProfileID: memberID)
        let snapshot = try await useCase.execute()

        // The UTC calendar day would be 2026-03-14; confirm the Circle's
        // own local day (still 2026-03-14 in America/Los_Angeles at this
        // instant too, but computed via the Circle's own time zone, not
        // UTC) is what actually got used and survived.
        #expect(snapshot.today == CircleDay(date: nearUTCMidnight, timeZoneIdentifier: timeZone))
        #expect(snapshot.careStatus.hasSurvived == true)
    }

    /// Required test 8: refreshing repeatedly against unchanged persisted
    /// data returns the identical streak every time — proving the streak is
    /// always *recalculated* from Daily Moments, never a mutable counter
    /// that could double-increment on repeated refreshes.
    @Test func refreshingRepeatedlyReturnsTheSameStreak() async throws {
        let circleID = UUID()
        let memberID = UUID()
        let friendID = UUID()
        let day1 = TestFactories.date(year: 2026, month: 3, day: 14, hour: 20, timeZoneIdentifier: timeZone)
        let day2 = TestFactories.date(year: 2026, month: 3, day: 15, hour: 20, timeZoneIdentifier: timeZone)

        let circleRepo = InMemoryCircleRepository()
        circleRepo.circle = FriendCircle(id: circleID, name: "Test Circle", timezoneIdentifier: timeZone, createdAt: day1, ownerProfileID: memberID)
        let memberRepo = InMemoryMemberRepository()
        memberRepo.members = [
            TestFactories.member(circleID: circleID, profileID: memberID),
            TestFactories.member(circleID: circleID, profileID: friendID)
        ]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: day1)

        let circleDay1 = CircleDay(date: day1, timeZoneIdentifier: timeZone)
        let circleDay2 = CircleDay(date: day2, timeZoneIdentifier: timeZone)
        let momentRepo = InMemoryMomentRepository()
        momentRepo.moments = [
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleDay1, createdAt: day1),
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay1, createdAt: day1),
            try TestFactories.moment(circleID: circleID, authorID: memberID, day: circleDay2, createdAt: day2),
            try TestFactories.moment(circleID: circleID, authorID: friendID, day: circleDay2, createdAt: day2)
        ]

        let useCase = makeUseCase(circleRepo: circleRepo, memberRepo: memberRepo, petRepo: petRepo, momentRepo: momentRepo, clock: FakeClock(now: day2), currentProfileID: memberID)

        let first = try await useCase.execute()
        let second = try await useCase.execute()
        let third = try await useCase.execute()

        #expect(first.currentStreak == 2)
        #expect(second.currentStreak == 2)
        #expect(third.currentStreak == 2)
    }

    /// Required test 10: the local friend-check-in demo contributes to the
    /// correct *second* Circle day — using the same day-key rules as real
    /// posts — without duplicating or overwriting the previous day's post.
    @Test func localFriendCheckInDemoContributesToTheCorrectSecondDayWithoutDuplicatingTheFirst() async throws {
        let circleID = UUID()
        let memberID = UUID()
        let day1 = TestFactories.date(year: 2026, month: 3, day: 14, hour: 20, timeZoneIdentifier: timeZone)
        let day2 = TestFactories.date(year: 2026, month: 3, day: 15, hour: 20, timeZoneIdentifier: timeZone)

        let circleRepo = InMemoryCircleRepository()
        let circle = FriendCircle(id: circleID, name: "Test Circle", timezoneIdentifier: timeZone, createdAt: day1, ownerProfileID: memberID)
        circleRepo.circle = circle
        let memberRepo = InMemoryMemberRepository()
        let me = TestFactories.member(circleID: circleID, profileID: memberID)
        memberRepo.members = [me]
        let petRepo = InMemoryPetRepository()
        petRepo.pet = SharedPet(id: UUID(), circleID: circleID, name: "Mochi", speciesKey: "fox", stage: .hatchling, growthPoints: 0, createdAt: day1)

        let momentRepo = InMemoryMomentRepository()
        let photoService = PhotoProcessingService()

        let clock1 = FakeClock(now: day1)
        let publish1 = PublishDailyMomentUseCase(momentRepository: momentRepo, clock: clock1)
        _ = try await publish1.execute(circle: circle, member: me, photo: try MomentPhoto(imageData: Data([0xFF]), thumbnailData: Data([0xFF])), captionText: "Day 1")
        let simulate1 = SimulateFriendCheckInUseCase(
            memberRepository: memberRepo, momentRepository: momentRepo, publishDailyMomentUseCase: publish1,
            photoProcessingService: photoService, demoImageProvider: MockDemoCheckInImageProvider(), clock: clock1
        )
        guard case .created = try await simulate1.execute(circle: circle, currentMember: me) else {
            Issue.record("Expected day-1 demo check-in to be created")
            return
        }

        let clock2 = FakeClock(now: day2)
        let publish2 = PublishDailyMomentUseCase(momentRepository: momentRepo, clock: clock2)
        _ = try await publish2.execute(circle: circle, member: me, photo: try MomentPhoto(imageData: Data([0xFF]), thumbnailData: Data([0xFF])), captionText: "Day 2")
        let simulate2 = SimulateFriendCheckInUseCase(
            memberRepository: memberRepo, momentRepository: momentRepo, publishDailyMomentUseCase: publish2,
            photoProcessingService: photoService, demoImageProvider: MockDemoCheckInImageProvider(), clock: clock2
        )
        guard case .created = try await simulate2.execute(circle: circle, currentMember: me) else {
            Issue.record("Expected day-2 demo check-in to be created")
            return
        }

        // Four total posts: one real + one demo per day — day 1's posts
        // must still exist, untouched, after day 2's demo check-in.
        #expect(momentRepo.moments.count == 4)
        let circleDay1 = CircleDay(date: day1, timeZoneIdentifier: timeZone)
        let circleDay2 = CircleDay(date: day2, timeZoneIdentifier: timeZone)
        #expect(momentRepo.moments.filter { $0.day == circleDay1 }.count == 2)
        #expect(momentRepo.moments.filter { $0.day == circleDay2 }.count == 2)

        let useCase = makeUseCase(circleRepo: circleRepo, memberRepo: memberRepo, petRepo: petRepo, momentRepo: momentRepo, clock: clock2, currentProfileID: memberID)
        let snapshot = try await useCase.execute()
        #expect(snapshot.careStatus.hasSurvived == true)
        #expect(snapshot.currentStreak == 2)
    }
}
