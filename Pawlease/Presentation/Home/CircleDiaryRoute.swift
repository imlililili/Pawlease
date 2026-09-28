import Foundation

/// Marker route for pushing the Circle Diary feed from Pet Home — there is
/// only one, so it carries no payload. Deliberately value-based rather than
/// a closure-based `NavigationLink`: `PetHomeView.body` re-evaluates
/// continuously (`observeCloudSync()`'s remote-change/sync-event loops), and
/// a closure-based `NavigationLink { CircleDiaryFeedView(...) }` reconstructs
/// its destination on every such re-render — confirmed, via direct
/// instrumentation, to spuriously re-push a fresh `CircleDiaryFeedView` on
/// top of whatever was already pushed deeper (e.g. an open Diary entry),
/// which is what made the Diary Entry screen impossible to stay on. Value-
/// based navigation only constructs its destination once, lazily, when this
/// specific route is actually pushed — immune to ancestor re-renders.
struct CircleDiaryRoute: Hashable {}
