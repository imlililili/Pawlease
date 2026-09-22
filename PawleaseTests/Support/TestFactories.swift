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

    static func member(
        id: UUID = UUID(),
        circleID: UUID = UUID(),
        profileID: UUID = UUID(),
        displayName: String = "Ava",
        role: CircleMemberRole = .member
    ) -> CircleMember {
        CircleMember(
            id: id,
            circleID: circleID,
            profileID: profileID,
            displayName: displayName,
            avatarEmoji: "🐼",
            joinedAt: Date(),
            role: role
        )
    }

    static func petHomeSnapshot(
        circleID: UUID = UUID(),
        petName: String = "Mochi",
        petSpeciesKey: String = "fox",
        currentStreak: Int = 3,
        contributorIDs: Set<UUID> = [UUID(), UUID()],
        requiredContributorCount: Int = 2,
        hasCurrentMemberPosted: Bool = true,
        dayValue: String = "2026-03-15"
    ) -> PetHomeSnapshot {
        let ownerID = UUID()
        let circle = FriendCircle(
            id: circleID, name: "The Pack", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: ownerID
        )
        let member = TestFactories.member(circleID: circleID, profileID: ownerID)
        let pet = SharedPet(
            id: UUID(), circleID: circleID, name: petName, speciesKey: petSpeciesKey,
            stage: .hatchling, growthPoints: 0, createdAt: Date()
        )
        let careStatus = DailyCareStatus(requiredContributorCount: requiredContributorCount, contributorIDs: contributorIDs)
        return PetHomeSnapshot(
            circle: circle,
            currentMember: member,
            pet: pet,
            today: CircleDay(value: dayValue),
            careStatus: careStatus,
            activityState: careStatus.hasSurvived ? .thriving : .resting,
            currentStreak: currentStreak,
            hasCurrentMemberPosted: hasCurrentMemberPosted,
            canViewTodayFeed: hasCurrentMemberPosted
        )
    }

    static func comment(
        id: UUID = UUID(),
        momentID: UUID = UUID(),
        authorID: UUID = UUID(),
        authorName: String = "Test Member",
        body: String = "Nice one!",
        createdAt: Date = Date(),
        isRemoved: Bool = false
    ) throws -> MomentComment {
        MomentComment(
            id: id,
            momentID: momentID,
            authorProfileID: authorID,
            authorNameSnapshot: authorName,
            body: try CommentBody(body),
            createdAt: createdAt,
            isRemoved: isRemoved
        )
    }
}
