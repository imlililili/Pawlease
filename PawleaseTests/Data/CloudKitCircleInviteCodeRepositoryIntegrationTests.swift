import Testing
import Foundation
import CloudKit
@testable import Pawlease

/// Integration tests against the REAL CloudKit public database
/// (`CKContainer(identifier: "iCloud.com.lili.Pawlease").publicCloudDatabase`).
/// Deliberately separate from every mock-based Use Case test above, and
/// disabled by default: they require a signed-in iCloud account, network
/// access, and the `CircleInviteCode` record type to already be deployed to
/// the container's schema (see the README's CloudKit Console setup
/// section) — none of which this environment (Personal Team provisioning,
/// no real device) can provide. Do not count these toward the mock-test
/// requirements; enable them manually on a properly provisioned device/
/// account to verify real public-database behavior.
@Suite(.disabled("Requires a real, schema-deployed CloudKit public database and a signed-in iCloud account — not available in this environment."))
struct CloudKitCircleInviteCodeRepositoryIntegrationTests {
    @Test
    func publishedCodeRoundTripsThroughTheRealPublicDatabase() async throws {
        let database = CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier).publicCloudDatabase
        let repository = CloudKitCircleInviteCodeRepository(database: database)

        let code = CircleInviteCode.generateRandom()
        let circleID = UUID()
        let now = Date()
        let details = CircleInviteCodeDetails(
            code: code, circleID: circleID,
            shareURL: URL(string: "https://www.icloud.com/share/integration-test")!,
            createdAt: now, expiresAt: now.addingTimeInterval(3600), isRevoked: false
        )

        let published = try await repository.publish(details)
        #expect(published.code == code)

        let fetched = try await repository.fetchCode(code)
        #expect(fetched.circleID == circleID)

        try await repository.revoke(code)
        let afterRevoke = try await repository.fetchCode(code)
        #expect(afterRevoke.isRevoked)
    }
}
