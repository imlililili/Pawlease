import Foundation
import Observation

/// Coordinates the Circle Settings workflow: loading Circle/member/account/
/// sharing state, and preparing a Circle invitation. Never touches Core
/// Data or CloudKit directly — invitation preparation only produces a
/// `UUID` (`preparedCircleID`); the View uses that to ask an
/// Infrastructure-layer adapter for the actual native sharing controller
/// and reports the outcome back via `handleSharingOutcome`.
@MainActor
@Observable
final class CircleSettingsViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var viewState: CircleSettingsViewState?
    private(set) var isPreparingInvitation = false
    private(set) var actionErrorMessage: String?

    /// Set once `prepareInvitation()` succeeds. The View observes this to
    /// fetch and present the native sharing controller.
    private(set) var preparedCircleID: UUID?

    private var circleID: UUID?
    private var receivedSharingOutcome = false

    private let loadPetHomeUseCase: LoadPetHomeUseCase
    private let loadCircleMembersUseCase: LoadCircleMembersUseCase
    private let checkCloudAccountUseCase: CheckCloudAccountUseCase
    private let loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase
    private let prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase
    private let clock: ClockProviding

    init(
        loadPetHomeUseCase: LoadPetHomeUseCase,
        loadCircleMembersUseCase: LoadCircleMembersUseCase,
        checkCloudAccountUseCase: CheckCloudAccountUseCase,
        loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase,
        prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase,
        clock: ClockProviding
    ) {
        self.loadPetHomeUseCase = loadPetHomeUseCase
        self.loadCircleMembersUseCase = loadCircleMembersUseCase
        self.checkCloudAccountUseCase = checkCloudAccountUseCase
        self.loadCircleSharingStateUseCase = loadCircleSharingStateUseCase
        self.prepareCircleInvitationUseCase = prepareCircleInvitationUseCase
        self.clock = clock
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await refresh()
    }

    func refresh() async {
        loadState = .loading
        do {
            let snapshot = try await loadPetHomeUseCase.execute()
            circleID = snapshot.circle.id

            let members = try await loadCircleMembersUseCase.execute(circleID: snapshot.circle.id)
            let accountAvailability = await checkCloudAccountUseCase.execute()

            var sharingState: CircleSharingState
            do {
                sharingState = try await loadCircleSharingStateUseCase.execute(circleID: snapshot.circle.id)
            } catch {
                sharingState = .unavailable
            }

            viewState = CircleSettingsViewState(
                circleName: snapshot.circle.name,
                petName: snapshot.pet.name,
                memberNames: members.map(\.displayName),
                accountAvailability: accountAvailability,
                sharingState: sharingState,
                lastUpdatedAt: clock.now
            )
            loadState = .loaded
        } catch {
            loadState = .error(Self.message(for: error))
        }
    }

    /// Requests invitation preparation. On success, the View reacts to
    /// `preparedCircleID` becoming non-nil by fetching and presenting the
    /// native sharing controller.
    func prepareInvitation() async {
        guard let circleID else { return }
        isPreparingInvitation = true
        actionErrorMessage = nil
        receivedSharingOutcome = false
        defer { isPreparingInvitation = false }

        do {
            try await prepareCircleInvitationUseCase.execute(circleID: circleID)
            preparedCircleID = circleID
        } catch let error as CircleSharingError {
            actionErrorMessage = error.displayMessage
        } catch {
            actionErrorMessage = "We couldn't prepare an invitation. Please try again."
        }
    }

    /// Called by the View once it has asked the Infrastructure adapter for
    /// a sharing controller (successfully or not) — clears the "ready to
    /// present" signal either way.
    func handleSharingControllerRequestCompleted() {
        preparedCircleID = nil
    }

    /// The Domain-safe outcome reported by `UICloudSharingControllerDelegate`,
    /// forwarded here by the View.
    func handleSharingOutcome(_ outcome: CloudSharingOutcome) async {
        receivedSharingOutcome = true
        switch outcome {
        case .saved, .stoppedSharing:
            await refresh()
        case .cancelled:
            break
        case .failed(let error):
            actionErrorMessage = error.displayMessage
        }
    }

    /// The sharing sheet was dismissed without any delegate callback firing
    /// — i.e. the user backed out. Distinct from a reported failure.
    func handleSharingSheetDismissed() async {
        guard !receivedSharingOutcome else { return }
        await handleSharingOutcome(.cancelled)
    }

    private static func message(for error: Error) -> String {
        if let domainError = error as? DomainError {
            switch domainError {
            case .circleNotFound: return "We couldn't find your Circle."
            case .memberNotFound: return "We couldn't find your profile in this Circle."
            case .petNotFound: return "Your pet is missing. Please try again."
            case .feedLocked, .momentNotFound, .commentNotFound, .notCommentAuthor:
                return "Something went wrong. Please try again."
            }
        }
        if let sharingError = error as? CircleSharingError {
            return sharingError.displayMessage
        }
        return "Something went wrong. Please try again."
    }
}
