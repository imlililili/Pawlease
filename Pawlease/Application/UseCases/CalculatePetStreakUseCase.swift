import Foundation

/// A single day's survival outcome, ordered for streak calculation.
struct DailyOutcome: Sendable, Equatable {
    let day: CircleDay
    let survived: Bool
}

/// Pure calculation of the current consecutive-day streak. `recentDaysDescending`
/// must be contiguous days immediately before today, most recent first (i.e.
/// yesterday, the day before, ...). The streak stops counting at the first
/// missed day — a gap resets it without touching pet growth or any stored
/// moment history.
struct CalculatePetStreakUseCase: Sendable {
    func execute(recentDaysDescending: [DailyOutcome], todaySurvived: Bool) -> Int {
        var streak = todaySurvived ? 1 : 0
        for outcome in recentDaysDescending {
            guard outcome.survived else { break }
            streak += 1
        }
        return streak
    }
}
