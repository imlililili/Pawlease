import Foundation

/// A dedicated navigation-path value for pushing to Diary Entry Detail.
/// Deliberately not a bare `UUID` — Pet Home's own `NavigationStack` already
/// uses `.navigationDestination(for: UUID.self)` for Daily Moments, and
/// reusing the same value type for a different destination in the same
/// stack is a well-known SwiftUI pitfall (the stack can't tell which
/// destination a raw `UUID` was meant for).
struct DiaryEntryRoute: Hashable {
    let entryID: UUID
}
