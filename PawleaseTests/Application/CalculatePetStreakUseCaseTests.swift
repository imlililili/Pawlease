import Testing
@testable import Pawlease

struct CalculatePetStreakUseCaseTests {
    @Test func missingADayResetsTheStreak() {
        let useCase = CalculatePetStreakUseCase()
        let recentDaysDescending = [
            DailyOutcome(day: CircleDay(value: "2026-03-14"), survived: false),
            DailyOutcome(day: CircleDay(value: "2026-03-13"), survived: true),
            DailyOutcome(day: CircleDay(value: "2026-03-12"), survived: true)
        ]

        let streak = useCase.execute(recentDaysDescending: recentDaysDescending, todaySurvived: false)

        #expect(streak == 0)
    }

    @Test func consecutiveSurvivedDaysAccumulateTheStreak() {
        let useCase = CalculatePetStreakUseCase()
        let recentDaysDescending = [
            DailyOutcome(day: CircleDay(value: "2026-03-14"), survived: true),
            DailyOutcome(day: CircleDay(value: "2026-03-13"), survived: true),
            DailyOutcome(day: CircleDay(value: "2026-03-12"), survived: false)
        ]

        let streak = useCase.execute(recentDaysDescending: recentDaysDescending, todaySurvived: true)

        #expect(streak == 3)
    }
}
