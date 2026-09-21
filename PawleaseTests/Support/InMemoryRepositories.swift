import Foundation
@testable import Pawlease

final class InMemoryCircleRepository: CircleRepository, @unchecked Sendable {
    var circle: FriendCircle?

    func fetchDefaultCircle() async throws -> FriendCircle? {
        circle
    }

    func saveCircle(_ circle: FriendCircle) async throws -> FriendCircle {
        self.circle = circle
        return circle
    }
}

final class InMemoryMemberRepository: MemberRepository, @unchecked Sendable {
    var members: [CircleMember] = []

    func fetchMembers(circleID: UUID) async throws -> [CircleMember] {
        members.filter { $0.circleID == circleID }
    }

    func saveMember(_ member: CircleMember) async throws -> CircleMember {
        members.removeAll { $0.id == member.id }
        members.append(member)
        return member
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
}
