import Foundation

/// The Pet Status widget's concise status line, derived purely from a
/// `WidgetSnapshot` — no WidgetKit dependency, so it's testable from the
/// main app's test target.
enum PetStatusDisplayStatus: Sendable, Equatable {
    /// At least the required number of distinct members have posted today.
    case survivedToday
    /// The current member has posted, but the Circle still needs another
    /// distinct contributor today.
    case waitingForAnotherFriend
    /// The current member hasn't posted today yet.
    case needsCurrentMemberToPost
    /// No real snapshot has ever been written (or it couldn't be read) —
    /// the placeholder is standing in.
    case noSharedData

    var label: String {
        switch self {
        case .survivedToday: "Pet is happy today"
        case .waitingForAnotherFriend: "Waiting for another friend"
        case .needsCurrentMemberToPost: "Your turn to share today"
        case .noSharedData: "No shared data yet"
        }
    }
}

/// Immutable display data for one Pet Status widget timeline entry —
/// everything a `TimelineEntry` needs, computed once, before it reaches any
/// WidgetKit-specific type.
struct PetStatusDisplay: Sendable, Equatable {
    let date: Date
    let snapshot: WidgetSnapshot
    let isPlaceholder: Bool
    let status: PetStatusDisplayStatus

    init(date: Date, snapshot: WidgetSnapshot, isPlaceholder: Bool) {
        self.date = date
        self.snapshot = snapshot
        self.isPlaceholder = isPlaceholder
        self.status = Self.status(for: snapshot, isPlaceholder: isPlaceholder)
    }

    /// Priority, most to least specific: a survived day is worth
    /// celebrating regardless of who posted; otherwise nudge the current
    /// member first (the most actionable state) before a generic "waiting"
    /// message.
    private static func status(for snapshot: WidgetSnapshot, isPlaceholder: Bool) -> PetStatusDisplayStatus {
        if isPlaceholder || snapshot == .placeholder {
            return .noSharedData
        }
        if snapshot.hasSurvivedToday {
            return .survivedToday
        }
        if !snapshot.hasCurrentMemberPostedToday {
            return .needsCurrentMemberToPost
        }
        return .waitingForAnotherFriend
    }
}
