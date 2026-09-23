/// Abstracts `WidgetCenter.shared.reloadTimelines(ofKind:)` so the
/// Application layer never imports WidgetKit directly — matching how
/// CloudKit and Core Data are kept out of Domain/Application elsewhere in
/// this app. Implemented by `WidgetKitTimelineReloader`.
protocol WidgetTimelineReloading: Sendable {
    func reloadTimelines(ofKind kind: String)
}
