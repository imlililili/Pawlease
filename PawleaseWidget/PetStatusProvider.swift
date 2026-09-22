import WidgetKit

/// One Pet Status widget timeline entry. Holds only immutable display data
/// (`PetStatusDisplay`, computed in `SharedKit` before this type ever sees
/// it) — never a managed object, a repository result, or anything else
/// that could tie the Widget extension to Core Data or CloudKit.
struct PetStatusEntry: TimelineEntry {
    let date: Date
    let display: PetStatusDisplay
}

/// Reads the shared snapshot through `WidgetSnapshotStoring` only — this
/// provider never touches Core Data, CloudKit, a repository, a Use Case, or
/// a managed object. Dependencies are injectable (`snapshotStore`, `now`)
/// so `PetStatusTimelinePlanning`, which this provider is a thin wrapper
/// around, can be unit tested from the main app's test target.
struct PetStatusProvider: TimelineProvider {
    private let snapshotStore: WidgetSnapshotStoring
    private let now: () -> Date

    init(
        snapshotStore: WidgetSnapshotStoring = AppGroupWidgetSnapshotStore(),
        now: @escaping () -> Date = Date.init
    ) {
        self.snapshotStore = snapshotStore
        self.now = now
    }

    /// Shown instantly in the widget gallery before any real data loads.
    func placeholder(in context: Context) -> PetStatusEntry {
        let date = now()
        return PetStatusEntry(date: date, display: PetStatusDisplay(date: date, snapshot: .placeholder, isPlaceholder: true))
    }

    /// The quick preview shown while the user is choosing/configuring the
    /// widget. Never reads real shared data — always the placeholder,
    /// matching Apple's guidance for `context.isPreview`.
    func getSnapshot(in context: Context, completion: @escaping (PetStatusEntry) -> Void) {
        let date = now()
        if context.isPreview {
            completion(PetStatusEntry(date: date, display: PetStatusDisplay(date: date, snapshot: .placeholder, isPlaceholder: true)))
            return
        }
        let display = PetStatusTimelinePlanning.makeDisplay(from: snapshotStore, at: date)
        completion(PetStatusEntry(date: date, display: display))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetStatusEntry>) -> Void) {
        let date = now()
        let display = PetStatusTimelinePlanning.makeDisplay(from: snapshotStore, at: date)
        let entry = PetStatusEntry(date: date, display: display)
        let refreshDate = PetStatusTimelinePlanning.nextRefreshDate(after: date)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}
