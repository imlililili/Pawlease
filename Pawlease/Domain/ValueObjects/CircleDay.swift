import Foundation

/// A calendar day scoped to a `FriendCircle`'s stored time zone rather than
/// the device's current time zone, so all members agree on when "today" is.
struct CircleDay: Sendable, Hashable, Comparable {
    let value: String

    /// Constructs a day directly from a stored `yyyy-MM-dd` value.
    init(value: String) {
        self.value = value
    }

    /// Derives the day key for `date` as observed in `timeZoneIdentifier`.
    init(date: Date, timeZoneIdentifier: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.value = String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func < (lhs: CircleDay, rhs: CircleDay) -> Bool {
        lhs.value < rhs.value
    }
}
