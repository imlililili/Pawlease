import Testing
import Foundation
@testable import Pawlease

struct PublishWidgetSnapshotUseCaseTests {
    @Test
    func survivedDailyStateIsReflectedInThePublishedSnapshot() async throws {
        let store = MockWidgetSnapshotStore()
        let reloader = MockWidgetTimelineReloader()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15, hour: 9))
        let useCase = PublishWidgetSnapshotUseCase(widgetSnapshotStore: store, widgetTimelineReloader: reloader, clock: clock)

        let circleID = UUID()
        let snapshot = TestFactories.petHomeSnapshot(
            circleID: circleID,
            petName: "Mochi",
            petSpeciesKey: "fox",
            currentStreak: 4,
            contributorIDs: [UUID(), UUID()],
            requiredContributorCount: 2,
            hasCurrentMemberPosted: true,
            dayValue: "2026-03-15"
        )

        await useCase.execute(from: snapshot)

        #expect(store.saveCallCount == 1)
        let saved = try #require(store.savedSnapshots.first)
        #expect(saved.circleID == circleID)
        #expect(saved.petName == "Mochi")
        #expect(saved.petSpeciesKey == "fox")
        #expect(saved.currentStreak == 4)
        #expect(saved.contributorCount == 2)
        #expect(saved.requiredContributorCount == 2)
        #expect(saved.hasSurvivedToday == true)
        #expect(saved.hasCurrentMemberPostedToday == true)
        #expect(saved.circleDayKey == "2026-03-15")
        #expect(saved.lastUpdated == clock.now)

        #expect(reloader.reloadCallCount == 1)
        #expect(reloader.reloadedKinds == [WidgetKind.petStatus])
    }

    @Test
    func nonSurvivedDailyStateIsReflectedInThePublishedSnapshot() async throws {
        let store = MockWidgetSnapshotStore()
        let reloader = MockWidgetTimelineReloader()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = PublishWidgetSnapshotUseCase(widgetSnapshotStore: store, widgetTimelineReloader: reloader, clock: clock)

        // Only one distinct contributor against a requirement of two:
        // the day has not survived.
        let snapshot = TestFactories.petHomeSnapshot(
            contributorIDs: [UUID()],
            requiredContributorCount: 2,
            hasCurrentMemberPosted: true
        )

        await useCase.execute(from: snapshot)

        let saved = try #require(store.savedSnapshots.first)
        #expect(saved.contributorCount == 1)
        #expect(saved.requiredContributorCount == 2)
        #expect(saved.hasSurvivedToday == false)
        #expect(reloader.reloadCallCount == 1)
    }

    @Test
    func failedSnapshotWriteSkipsTheTimelineReload() async {
        struct StubWriteError: Error {}

        let store = MockWidgetSnapshotStore()
        store.saveError = StubWriteError()
        let reloader = MockWidgetTimelineReloader()
        let clock = FakeClock(now: Date())
        let useCase = PublishWidgetSnapshotUseCase(widgetSnapshotStore: store, widgetTimelineReloader: reloader, clock: clock)

        await useCase.execute(from: TestFactories.petHomeSnapshot())

        #expect(store.saveCallCount == 1)
        #expect(store.savedSnapshots.isEmpty)
        // WidgetCenter.shared.reloadTimelines(ofKind:) must only be called
        // after a *successful* write.
        #expect(reloader.reloadCallCount == 0)
    }
}
