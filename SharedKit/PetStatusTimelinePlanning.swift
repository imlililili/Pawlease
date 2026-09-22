import Foundation

/// Pure, framework-independent timeline-scheduling logic for the Pet Status
/// widget. Deliberately separate from the actual `TimelineProvider`
/// conformance (which lives in the Widget extension target and requires
/// `import WidgetKit`), so this logic can be unit tested from the main
/// app's test target via `@testable import Pawlease` — `SharedKit` compiles
/// into both.
enum PetStatusTimelinePlanning {
    /// Loads the current snapshot through `store` and builds the single
    /// display entry the timeline should show right now.
    static func makeDisplay(from store: WidgetSnapshotStoring, at date: Date) -> PetStatusDisplay {
        let snapshot = store.loadSnapshot()
        return PetStatusDisplay(date: date, snapshot: snapshot, isPlaceholder: snapshot == .placeholder)
    }

    /// A conservative next-refresh date: the sooner of "one hour from now"
    /// or "the next local midnight" — frequent enough to pick up a new
    /// Circle day at the boundary without polling aggressively. The main
    /// app already calls `WidgetCenter.reloadTimelines(ofKind:)` after
    /// every successful snapshot write, so this is only a safety net for
    /// when the app hasn't run in a while. Never force-unwraps.
    static func nextRefreshDate(after date: Date, calendar: Calendar = .current) -> Date {
        let hourly = date.addingTimeInterval(60 * 60)
        let nextMidnight = calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        )
        guard let nextMidnight else { return hourly }
        return min(hourly, nextMidnight)
    }
}
