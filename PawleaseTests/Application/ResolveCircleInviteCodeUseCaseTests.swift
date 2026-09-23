import Testing
import Foundation
@testable import Pawlease

/// Mock-based only — never touches real CloudKit.
struct ResolveCircleInviteCodeUseCaseTests {
    @Test
    func malformedCodeIsRejectedBeforeAnyRepositoryAccess() async {
        let repository = MockCircleInviteCodeRepository()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let useCase = ResolveCircleInviteCodeUseCase(circleInviteCodeRepository: repository, clock: clock)

        await #expect(throws: CircleInviteCodeError.malformed) {
            _ = try await useCase.execute(rawInput: "not-a-code")
        }
        #expect(repository.fetchCodeCallCount == 0)
    }

    @Test
    func activeCodeResolvesToACKShareURL() async throws {
        let code = CircleInviteCode.generateRandom()
        let circleID = UUID()
        let shareURL = try #require(URL(string: "https://www.icloud.com/share/xyz"))
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let repository = MockCircleInviteCodeRepository()
        repository.fetchCodeResult = CircleInviteCodeDetails(
            code: code, circleID: circleID, shareURL: shareURL,
            createdAt: clock.now, expiresAt: clock.now.addingTimeInterval(3600), isRevoked: false
        )
        let useCase = ResolveCircleInviteCodeUseCase(circleInviteCodeRepository: repository, clock: clock)

        let details = try await useCase.execute(rawInput: code.formatted)

        #expect(details.shareURL == shareURL)
        #expect(details.circleID == circleID)
        #expect(repository.fetchCodeCapturedCodes == [code])
    }

    @Test
    func expiredCodeIsRejected() async {
        let code = CircleInviteCode.generateRandom()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let repository = MockCircleInviteCodeRepository()
        repository.fetchCodeResult = CircleInviteCodeDetails(
            code: code, circleID: UUID(), shareURL: URL(string: "https://www.icloud.com/share/xyz")!,
            createdAt: clock.now.addingTimeInterval(-3 * 24 * 3600),
            expiresAt: clock.now.addingTimeInterval(-1 * 24 * 3600), // expired yesterday
            isRevoked: false
        )
        let useCase = ResolveCircleInviteCodeUseCase(circleInviteCodeRepository: repository, clock: clock)

        await #expect(throws: CircleInviteCodeError.expired) {
            _ = try await useCase.execute(rawInput: code.formatted)
        }
    }

    @Test
    func revokedCodeIsRejected() async {
        let code = CircleInviteCode.generateRandom()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let repository = MockCircleInviteCodeRepository()
        repository.fetchCodeResult = CircleInviteCodeDetails(
            code: code, circleID: UUID(), shareURL: URL(string: "https://www.icloud.com/share/xyz")!,
            createdAt: clock.now, expiresAt: clock.now.addingTimeInterval(3600), isRevoked: true
        )
        let useCase = ResolveCircleInviteCodeUseCase(circleInviteCodeRepository: repository, clock: clock)

        await #expect(throws: CircleInviteCodeError.revoked) {
            _ = try await useCase.execute(rawInput: code.formatted)
        }
    }

    @Test
    func missingCodeReturnsADomainNotFoundError() async {
        let code = CircleInviteCode.generateRandom()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let repository = MockCircleInviteCodeRepository()
        repository.fetchCodeError = CircleInviteCodeError.notFound
        let useCase = ResolveCircleInviteCodeUseCase(circleInviteCodeRepository: repository, clock: clock)

        await #expect(throws: CircleInviteCodeError.notFound) {
            _ = try await useCase.execute(rawInput: code.formatted)
        }
    }

    @Test
    func offlineResolutionProducesARetryableError() async {
        let code = CircleInviteCode.generateRandom()
        let clock = FakeClock(now: TestFactories.date(year: 2026, month: 3, day: 15))
        let repository = MockCircleInviteCodeRepository()
        repository.fetchCodeError = CircleInviteCodeError.offline
        let useCase = ResolveCircleInviteCodeUseCase(circleInviteCodeRepository: repository, clock: clock)

        await #expect(throws: CircleInviteCodeError.offline) {
            _ = try await useCase.execute(rawInput: code.formatted)
        }
    }
}
