import Foundation
@testable import Pawlease

enum TestFactories {
    static func moment(
        circleID: UUID = UUID(),
        authorID: UUID = UUID(),
        day: CircleDay,
        caption: String = "Hello",
        createdAt: Date = Date()
    ) throws -> DailyMoment {
        DailyMoment(
            id: UUID(),
            circleID: circleID,
            authorProfileID: authorID,
            authorNameSnapshot: "Test Member",
            day: day,
            caption: try MomentCaption(caption),
            moodEmoji: nil,
            photo: try MomentPhoto(imageData: Data([0xFF, 0xD8]), thumbnailData: Data([0xFF, 0xD8])),
            createdAt: createdAt
        )
    }

    static func date(year: Int, month: Int, day: Int, hour: Int = 12, timeZoneIdentifier: String = "UTC") -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
