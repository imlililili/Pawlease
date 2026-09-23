import CoreData
import Foundation

/// Implements `UserProfileRepository` against `UserProfileEntity` in the
/// `Private` Core Data configuration. Fetch-or-create, never a Core Data
/// unique constraint: a fetch-then-conditionally-insert inside one
/// `context.perform` block is what actually prevents a second profile row
/// from ever being created.
nonisolated final class CoreDataUserProfileRepository: UserProfileRepository, @unchecked Sendable {
    private let container: NSPersistentContainer
    private let defaultProfileID: UUID
    private let defaultDisplayName: String
    private let defaultAvatarEmoji: String
    private let clock: ClockProviding

    init(
        container: NSPersistentContainer,
        defaultProfileID: UUID = DemoSeed.currentProfileID,
        defaultDisplayName: String = "You",
        defaultAvatarEmoji: String = "🦊",
        clock: ClockProviding
    ) {
        self.container = container
        self.defaultProfileID = defaultProfileID
        self.defaultDisplayName = defaultDisplayName
        self.defaultAvatarEmoji = defaultAvatarEmoji
        self.clock = clock
    }

    func fetchOrCreateCurrentProfile() async throws -> UserProfile {
        let context = container.newBackgroundContext()
        let defaultProfileID = defaultProfileID
        let defaultDisplayName = defaultDisplayName
        let defaultAvatarEmoji = defaultAvatarEmoji
        let now = clock.now

        return try await context.perform {
            let request = UserProfileEntity.fetchRequest()
            request.fetchLimit = 1
            if let entity = try context.fetch(request).first {
                return UserProfileMapper.toDomain(entity)
            }

            let profile = UserProfile(
                id: defaultProfileID,
                displayName: defaultDisplayName,
                avatarEmoji: defaultAvatarEmoji,
                createdAt: now
            )
            let entity = UserProfileEntity(context: context)
            UserProfileMapper.apply(profile, to: entity)
            try context.save()
            return profile
        }
    }
}
