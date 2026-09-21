import Foundation

/// Assembles everything the Pet Home screen needs: the Circle, the current
/// member, the pet, today's care status, today's derived activity state, and
/// the current streak. Orchestrates repositories and the pure calculation
/// Use Cases — it holds no business rules of its own.
struct LoadPetHomeUseCase: Sendable {
    let circleRepository: CircleRepository
    let memberRepository: MemberRepository
    let petRepository: PetRepository
    let momentRepository: MomentRepository
    let calculateDailyCareStatus: CalculateDailyCareStatusUseCase
    let calculatePetStreak: CalculatePetStreakUseCase
    let clock: ClockProviding
    let currentProfileID: UUID
    let streakLookbackDays: Int

    init(
        circleRepository: CircleRepository,
        memberRepository: MemberRepository,
        petRepository: PetRepository,
        momentRepository: MomentRepository,
        calculateDailyCareStatus: CalculateDailyCareStatusUseCase = CalculateDailyCareStatusUseCase(),
        calculatePetStreak: CalculatePetStreakUseCase = CalculatePetStreakUseCase(),
        clock: ClockProviding,
        currentProfileID: UUID,
        streakLookbackDays: Int = 30
    ) {
        self.circleRepository = circleRepository
        self.memberRepository = memberRepository
        self.petRepository = petRepository
        self.momentRepository = momentRepository
        self.calculateDailyCareStatus = calculateDailyCareStatus
        self.calculatePetStreak = calculatePetStreak
        self.clock = clock
        self.currentProfileID = currentProfileID
        self.streakLookbackDays = streakLookbackDays
    }

    func execute() async throws -> PetHomeSnapshot {
        guard let circle = try await circleRepository.fetchDefaultCircle() else {
            throw DomainError.circleNotFound
        }
        let members = try await memberRepository.fetchMembers(circleID: circle.id)
        guard let currentMember = members.first(where: { $0.profileID == currentProfileID }) else {
            throw DomainError.memberNotFound
        }
        guard let pet = try await petRepository.fetchPet(circleID: circle.id) else {
            throw DomainError.petNotFound
        }

        let today = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)
        let todaysMoments = try await momentRepository.fetchMoments(circleID: circle.id, day: today)
        let careStatus = calculateDailyCareStatus.execute(moments: todaysMoments)
        let hasPosted = todaysMoments.contains { $0.authorProfileID == currentProfileID }

        let recentOutcomes = try await recentDaysDescending(circle: circle, today: today)
        let streak = calculatePetStreak.execute(
            recentDaysDescending: recentOutcomes,
            todaySurvived: careStatus.hasSurvived
        )

        return PetHomeSnapshot(
            circle: circle,
            currentMember: currentMember,
            pet: pet,
            today: today,
            careStatus: careStatus,
            activityState: careStatus.hasSurvived ? .thriving : .resting,
            currentStreak: streak,
            hasCurrentMemberPosted: hasPosted,
            canViewTodayFeed: hasPosted
        )
    }

    /// Builds the contiguous run of days immediately before `today` (most
    /// recent first) and their survival outcomes, for streak calculation.
    private func recentDaysDescending(circle: FriendCircle, today: CircleDay) async throws -> [DailyOutcome] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: circle.timezoneIdentifier) ?? TimeZone(identifier: "UTC")!

        let todayComponents = today.value.split(separator: "-").compactMap { Int($0) }
        guard todayComponents.count == 3,
              let todayDate = calendar.date(from: DateComponents(
                  year: todayComponents[0], month: todayComponents[1], day: todayComponents[2], hour: 12
              ))
        else {
            return []
        }

        var days: [CircleDay] = []
        for offset in 1...streakLookbackDays {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: todayDate) else { continue }
            days.append(CircleDay(date: date, timeZoneIdentifier: circle.timezoneIdentifier))
        }

        let moments = try await momentRepository.fetchMoments(circleID: circle.id, days: days)
        let momentsByDay = Dictionary(grouping: moments, by: \.day)

        return days.map { day in
            let dayMoments = momentsByDay[day] ?? []
            let survived = calculateDailyCareStatus.execute(moments: dayMoments).hasSurvived
            return DailyOutcome(day: day, survived: survived)
        }
    }
}
