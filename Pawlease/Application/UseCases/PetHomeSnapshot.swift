import Foundation

/// Purpose-built result type for `LoadPetHomeUseCase`, aggregating exactly
/// what the Pet Home screen needs to render.
struct PetHomeSnapshot: Sendable, Equatable {
    let circle: FriendCircle
    let currentMember: CircleMember
    let pet: SharedPet
    let today: CircleDay
    let careStatus: DailyCareStatus
    let activityState: PetActivityState
    let currentStreak: Int
    let hasCurrentMemberPosted: Bool
    let canViewTodayFeed: Bool
}
