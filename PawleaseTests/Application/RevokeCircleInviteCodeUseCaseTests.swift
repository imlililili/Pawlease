import Testing
import Foundation
@testable import Pawlease

struct RevokeCircleInviteCodeUseCaseTests {
    @Test
    func revocationCallsTheRepositoryWithTheGivenCode() async throws {
        let code = CircleInviteCode.generateRandom()
        let repository = MockCircleInviteCodeRepository()
        let useCase = RevokeCircleInviteCodeUseCase(circleInviteCodeRepository: repository)

        try await useCase.execute(code: code)

        #expect(repository.revokedCodes == [code])
    }

    @Test
    func revocationFailureRemainsRetryable() async {
        let code = CircleInviteCode.generateRandom()
        let repository = MockCircleInviteCodeRepository()
        repository.revokeError = CircleInviteCodeError.offline
        let useCase = RevokeCircleInviteCodeUseCase(circleInviteCodeRepository: repository)

        await #expect(throws: CircleInviteCodeError.offline) {
            try await useCase.execute(code: code)
        }

        // Nothing about the failed attempt prevents calling again.
        repository.revokeError = nil
        try? await useCase.execute(code: code)
        #expect(repository.revokeCallCount == 2)
        #expect(repository.revokedCodes == [code, code])
    }
}
