import Foundation
@testable import Pawlease

final class InMemoryCircleRepository: CircleRepository, @unchecked Sendable {
    var circle: FriendCircle?

    func fetchDefaultCircle() async throws -> FriendCircle? {
        circle
    }

    func fetchCircle(id: UUID) async throws -> FriendCircle? {
        circle?.id == id ? circle : nil
    }

    func saveCircle(_ circle: FriendCircle) async throws -> FriendCircle {
        self.circle = circle
        return circle
    }
}

final class InMemoryMemberRepository: MemberRepository, @unchecked Sendable {
    var members: [CircleMember] = []

    func fetchMembers(circleID: UUID) async throws -> [CircleMember] {
        members
            .filter { $0.circleID == circleID }
            .sorted { $0.joinedAt == $1.joinedAt ? $0.profileID.uuidString < $1.profileID.uuidString : $0.joinedAt < $1.joinedAt }
    }

    /// Mirrors `CoreDataMemberRepository.saveMember`'s upsert key — at most
    /// one Member per `(circleID, profileID)`, never keyed on `member.id`
    /// alone — so Application-layer tests against this double actually
    /// exercise the same duplicate-prevention guarantee the real
    /// repository provides.
    @discardableResult
    func saveMember(_ member: CircleMember) async throws -> CircleMember {
        if let index = members.firstIndex(where: { $0.circleID == member.circleID && $0.profileID == member.profileID }) {
            members[index] = member
        } else {
            members.append(member)
        }
        return member
    }

    func deleteMember(circleID: UUID, profileID: UUID) async throws {
        members.removeAll { $0.circleID == circleID && $0.profileID == profileID }
    }
}

final class InMemoryUserProfileRepository: UserProfileRepository, @unchecked Sendable {
    var profile: UserProfile?
    private(set) var fetchOrCreateCallCount = 0

    func fetchOrCreateCurrentProfile() async throws -> UserProfile {
        fetchOrCreateCallCount += 1
        if let profile { return profile }
        let created = UserProfile(id: UUID(), displayName: "You", avatarEmoji: "🦊", createdAt: Date())
        profile = created
        return created
    }
}

final class InMemoryPetRepository: PetRepository, @unchecked Sendable {
    var pet: SharedPet?

    func fetchPet(circleID: UUID) async throws -> SharedPet? {
        pet
    }

    func savePet(_ pet: SharedPet) async throws -> SharedPet {
        self.pet = pet
        return pet
    }
}

final class InMemoryMomentRepository: MomentRepository, @unchecked Sendable {
    var moments: [DailyMoment] = []

    func fetchMoment(id: UUID) async throws -> DailyMoment? {
        moments.first { $0.id == id }
    }

    func fetchMoments(circleID: UUID, day: CircleDay) async throws -> [DailyMoment] {
        moments.filter { $0.circleID == circleID && $0.day == day }
    }

    func fetchMoments(circleID: UUID, days: [CircleDay]) async throws -> [DailyMoment] {
        let daySet = Set(days)
        return moments.filter { $0.circleID == circleID && daySet.contains($0.day) }
    }

    func hasMemberPosted(circleID: UUID, profileID: UUID, day: CircleDay) async throws -> Bool {
        moments.contains { $0.circleID == circleID && $0.authorProfileID == profileID && $0.day == day }
    }

    /// Mirrors the Core Data repository's documented replace policy: an
    /// existing moment for the same author and day is overwritten in place.
    func saveMoment(_ moment: DailyMoment) async throws -> DailyMoment {
        if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index] = moment
        } else if let index = moments.firstIndex(where: {
            $0.circleID == moment.circleID && $0.authorProfileID == moment.authorProfileID && $0.day == moment.day
        }) {
            moments[index] = moment
        } else {
            moments.append(moment)
        }
        return moment
    }

    func deleteMoments(circleID: UUID, authorProfileID: UUID) async throws {
        moments.removeAll { $0.circleID == circleID && $0.authorProfileID == authorProfileID }
    }
}
