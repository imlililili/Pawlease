import Testing
@testable import Pawlease

struct CheckCloudAccountUseCaseTests {
    @Test
    func accountStatusMapsPlatformStatesIntoDomainStates() async {
        let provider = MockCloudAccountStatusProvider()
        let useCase = CheckCloudAccountUseCase(cloudAccountStatusProvider: provider)

        let allStates: [CloudAccountAvailability] = [.available, .noAccount, .restricted, .temporarilyUnavailable, .unknown]
        for status in allStates {
            provider.stubbedStatus = status
            let result = await useCase.execute()
            #expect(result == status)
        }

        #expect(provider.currentStatusCallCount == allStates.count)
    }
}
