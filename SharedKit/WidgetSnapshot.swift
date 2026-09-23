import Foundation

/// A small, framework-independent read model for the (future) Pet Status
/// widget. Written by the main app after Pet Home state is recalculated or
/// a daily moment is published; read by the Widget extension. Contains only
/// what a glanceable widget needs — never a `CKShare`, `NSManagedObject`,
/// or anything else framework-specific.
///
/// This type is compiled into both the `Pawlease` app target and the
/// `PawleaseWidgetExtension` target, so the two sides always agree on the
/// wire format without sharing any other code (Core Data, CloudKit, or
/// otherwise).
struct WidgetSnapshot: Codable, Sendable, Equatable {
    let circleID: UUID
    let petName: String
    let petSpeciesKey: String
    let currentStreak: Int
    let contributorCount: Int
    let requiredContributorCount: Int
    let hasSurvivedToday: Bool
    let hasCurrentMemberPostedToday: Bool
    let circleDayKey: String
    let lastUpdated: Date

    init(
        circleID: UUID,
        petName: String,
        petSpeciesKey: String,
        currentStreak: Int,
        contributorCount: Int,
        requiredContributorCount: Int,
        hasSurvivedToday: Bool,
        hasCurrentMemberPostedToday: Bool,
        circleDayKey: String,
        lastUpdated: Date
    ) {
        self.circleID = circleID
        self.petName = petName
        self.petSpeciesKey = petSpeciesKey
        self.currentStreak = currentStreak
        self.contributorCount = contributorCount
        self.requiredContributorCount = requiredContributorCount
        self.hasSurvivedToday = hasSurvivedToday
        self.hasCurrentMemberPostedToday = hasCurrentMemberPostedToday
        self.circleDayKey = circleDayKey
        self.lastUpdated = lastUpdated
    }

    /// A safe placeholder for when no shared snapshot exists yet — before
    /// the main app has ever written one, or if a previous write or decode
    /// failed. Deliberately generic rather than zeroed/garbage-looking, so
    /// a fresh widget install never renders broken-looking data.
    static let placeholder = WidgetSnapshot(
        circleID: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        petName: "Your Pet",
        petSpeciesKey: "fox",
        currentStreak: 0,
        contributorCount: 0,
        requiredContributorCount: 2,
        hasSurvivedToday: false,
        hasCurrentMemberPostedToday: false,
        circleDayKey: "",
        lastUpdated: .distantPast
    )
}
