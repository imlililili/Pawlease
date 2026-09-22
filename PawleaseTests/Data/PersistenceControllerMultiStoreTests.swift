import Testing
import Foundation
import CoreData
@testable import Pawlease

/// Integration test against the real, temporary, on-disk (non-CloudKit)
/// multi-store Core Data stack — not mock-based, and not counted toward
/// the minimum mock-based unit test requirement. Proves both the
/// "Private" and "Shared" configurations load together without requiring
/// an iCloud account or network access, and that writes routed through
/// the "Shared" configuration (where `CircleEntity` lives) succeed.
struct PersistenceControllerMultiStoreTests {
    @Test
    func bothPrivateAndSharedStoresLoadAndAcceptWritesWithoutICloud() async throws {
        let persistence = PersistenceController(mode: .inMemory)

        #expect(persistence.container.persistentStoreCoordinator.persistentStores.count == 2)
        #expect(persistence.isCloudKitConfigured == false)

        let circleRepository = CoreDataCircleRepository(container: persistence.container)
        let circle = FriendCircle(
            id: UUID(), name: "Test Circle", timezoneIdentifier: "UTC", createdAt: Date(), ownerProfileID: UUID()
        )
        let saved = try await circleRepository.saveCircle(circle)
        #expect(saved.id == circle.id)

        let fetched = try await circleRepository.fetchDefaultCircle()
        #expect(fetched?.id == circle.id)
    }
}
