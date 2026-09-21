import Foundation

/// Publishes the current member's moment for today.
///
/// Documented duplicate policy: if the member already has a moment for the
/// Circle's current day, publishing again **replaces** that moment in place
/// (same identity, updated content) rather than rejecting the attempt or
/// creating a second row. This lets a member fix a typo or swap a photo
/// without ever counting as two contributors for the same day.
struct PublishDailyMomentUseCase: Sendable {
    let momentRepository: MomentRepository
    let clock: ClockProviding

    func execute(
        circle: FriendCircle,
        member: CircleMember,
        photo: MomentPhoto,
        captionText: String,
        moodEmoji: String?
    ) async throws -> DailyMoment {
        let caption = try MomentCaption(captionText)
        let day = CircleDay(date: clock.now, timeZoneIdentifier: circle.timezoneIdentifier)

        let existing = try await momentRepository
            .fetchMoments(circleID: circle.id, day: day)
            .first { $0.authorProfileID == member.profileID }

        let moment = DailyMoment(
            id: existing?.id ?? UUID(),
            circleID: circle.id,
            authorProfileID: member.profileID,
            authorNameSnapshot: member.displayName,
            day: day,
            caption: caption,
            moodEmoji: moodEmoji,
            photo: photo,
            createdAt: existing?.createdAt ?? clock.now
        )

        return try await momentRepository.saveMoment(moment)
    }
}
