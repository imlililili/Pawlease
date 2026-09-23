import WidgetKit

/// The only file in the main app target that imports WidgetKit for the
/// snapshot-publishing boundary.
struct WidgetKitTimelineReloader: WidgetTimelineReloading {
    func reloadTimelines(ofKind kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
