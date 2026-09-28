import Foundation

/// How long a Circle Diary entry stays visible in the shared feed before it
/// moves to its author's private Archive. Owns the pure expiry-hour math so
/// `PublishDiaryEntryUseCase` never hardcodes `24`/`72`/`168` itself.
enum DiaryVisibilityDuration: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    case oneDay
    case threeDays
    case sevenDays
    case permanent

    /// `nil` for `.permanent` — it never expires.
    var expiryHours: Int? {
        switch self {
        case .oneDay: 24
        case .threeDays: 72
        case .sevenDays: 168
        case .permanent: nil
        }
    }

    /// The exact expiry instant for an entry created at `createdAt`, or
    /// `nil` for a permanent entry. Pure function of its inputs — never
    /// reads the system clock itself.
    func expiresAt(from createdAt: Date) -> Date? {
        guard let expiryHours else { return nil }
        return createdAt.addingTimeInterval(TimeInterval(expiryHours) * 3600)
    }

    var displayName: String {
        switch self {
        case .oneDay: "1 day"
        case .threeDays: "3 days"
        case .sevenDays: "7 days"
        case .permanent: "Permanent"
        }
    }
}
