/// The widget's `kind` identifier, shared between the reload call site (main
/// app) and the widget's own `StaticConfiguration(kind:)` (Widget
/// extension), so the two can never drift apart into mismatched strings.
enum WidgetKind {
    static let petStatus = "PawleaseWidget"
}
