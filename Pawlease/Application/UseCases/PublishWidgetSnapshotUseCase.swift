import Foundation

/// Maps the current `PetHomeSnapshot` into a `WidgetSnapshot` and publishes
/// it for the (future) widget to read. Called after Pet Home state is
/// recalculated or a daily moment is published — never on its own timer.
///
/// Never throws: a failed save is swallowed (the widget simply keeps
/// showing its last snapshot, or the placeholder, until the next
/// successful publish) and `WidgetTimelineReloading.reloadTimelines(ofKind:)`
/// is only called after a successful write.
struct PublishWidgetSnapshotUseCase: Sendable {
    let widgetSnapshotStore: WidgetSnapshotStoring
    let widgetTimelineReloader: WidgetTimelineReloading
    let clock: ClockProviding

    func execute(from snapshot: PetHomeSnapshot) async {
        let widgetSnapshot = WidgetSnapshot(
            circleID: snapshot.circle.id,
            petName: snapshot.pet.name,
            petSpeciesKey: snapshot.pet.speciesKey,
            currentStreak: snapshot.currentStreak,
            contributorCount: snapshot.careStatus.contributorCount,
            requiredContributorCount: snapshot.careStatus.requiredContributorCount,
            hasSurvivedToday: snapshot.careStatus.hasSurvived,
            hasCurrentMemberPostedToday: snapshot.hasCurrentMemberPosted,
            circleDayKey: snapshot.today.value,
            lastUpdated: clock.now
        )

        do {
            try widgetSnapshotStore.save(widgetSnapshot)
            widgetTimelineReloader.reloadTimelines(ofKind: WidgetKind.petStatus)
        } catch {
            // Deliberately silent: the widget just keeps its last good
            // snapshot (or the placeholder) rather than the app crashing
            // or surfacing a write failure the user can't act on.
        }
    }
}
