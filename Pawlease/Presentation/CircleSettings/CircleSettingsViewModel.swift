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

    /// Presentation-ready state for the owner's invite-code section.
    enum InviteCodeState: Equatable {
        case none
        case loading
        case active(CircleInviteCodeDisplay)
        case revoked
        case error(String)
    }

    struct CircleInviteCodeDisplay: Equatable {
        let formattedCode: String
        let shareURL: URL
        let expiresAtLabel: String
    }

    private(set) var loadState: LoadState = .idle
    private(set) var viewState: CircleSettingsViewState?
    private(set) var isPreparingInvitation = false
    private(set) var actionErrorMessage: String?

    private(set) var inviteCodeState: InviteCodeState = .none
    private(set) var isCreatingInviteCode = false
    private(set) var isRevokingInviteCode = false
    private(set) var didCopyInviteCode = false

    /// Set once `prepareInvitation()` succeeds. The View observes this to
    /// fetch and present the native sharing controller.
    private(set) var preparedCircleID: UUID?

    private var circleID: UUID?
    private var receivedSharingOutcome = false
    /// The actual code behind `inviteCodeState`'s display — held privately
    /// so `revokeInviteCode()` has the record ID to revoke without the View
    /// needing to know about `CircleInviteCode` at all.
    private var currentInviteCode: CircleInviteCode?

    private let loadPetHomeUseCase: LoadPetHomeUseCase
    private let loadCircleMembersUseCase: LoadCircleMembersUseCase
    private let checkCloudAccountUseCase: CheckCloudAccountUseCase
    private let loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase
    private let prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase
    private let loadActiveCircleInviteCodeUseCase: LoadActiveCircleInviteCodeUseCase
    private let createCircleInviteCodeUseCase: CreateCircleInviteCodeUseCase
    private let revokeCircleInviteCodeUseCase: RevokeCircleInviteCodeUseCase
    private let clock: ClockProviding

    init(
        loadPetHomeUseCase: LoadPetHomeUseCase,
        loadCircleMembersUseCase: LoadCircleMembersUseCase,
        checkCloudAccountUseCase: CheckCloudAccountUseCase,
        loadCircleSharingStateUseCase: LoadCircleSharingStateUseCase,
        prepareCircleInvitationUseCase: PrepareCircleInvitationUseCase,
        loadActiveCircleInviteCodeUseCase: LoadActiveCircleInviteCodeUseCase,
        createCircleInviteCodeUseCase: CreateCircleInviteCodeUseCase,
        revokeCircleInviteCodeUseCase: RevokeCircleInviteCodeUseCase,
        clock: ClockProviding
    ) {
        self.loadPetHomeUseCase = loadPetHomeUseCase
        self.loadCircleMembersUseCase = loadCircleMembersUseCase
        self.checkCloudAccountUseCase = checkCloudAccountUseCase
        self.loadCircleSharingStateUseCase = loadCircleSharingStateUseCase
        self.prepareCircleInvitationUseCase = prepareCircleInvitationUseCase
        self.loadActiveCircleInviteCodeUseCase = loadActiveCircleInviteCodeUseCase
        self.createCircleInviteCodeUseCase = createCircleInviteCodeUseCase
        self.revokeCircleInviteCodeUseCase = revokeCircleInviteCodeUseCase
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
            await refreshInviteCodeState(circleID: snapshot.circle.id)
        } catch {
            loadState = .error(Self.message(for: error))
        }
    }

    /// Reloads the owner's active invite code, if any. Kept separate from
    /// the rest of `refresh()`'s error handling — a failure here degrades
    /// to "no code shown" rather than failing the whole screen, since this
    /// is a secondary section.
    private func refreshInviteCodeState(circleID: UUID) async {
        do {
            guard let active = try await loadActiveCircleInviteCodeUseCase.execute(circleID: circleID),
                  !active.isExpired(asOf: clock.now)
            else {
                currentInviteCode = nil
                inviteCodeState = .none
                return
            }
            currentInviteCode = active.code
            inviteCodeState = .active(Self.display(for: active, now: clock.now))
        } catch {
            currentInviteCode = nil
            inviteCodeState = .none
        }
    }

    /// Creates (or replaces) the owner's invite code for this Circle.
    func createInviteCode() async {
        guard let circleID else { return }
        isCreatingInviteCode = true
        inviteCodeState = .loading
        defer { isCreatingInviteCode = false }

        do {
            let details = try await createCircleInviteCodeUseCase.execute(circleID: circleID)
            currentInviteCode = details.code
            inviteCodeState = .active(Self.display(for: details, now: clock.now))
        } catch let error as CircleSharingError {
            // `CreateCircleInviteCodeUseCase` delegates CKShare preparation
            // to `PrepareCircleInvitationUseCase`, which throws
            // `CircleSharingError` (not `CircleInviteCodeError`) for an
            // unavailable iCloud account — this must be caught explicitly,
            // or it falls through to the generic message below and the
            // account state (already shown correctly elsewhere on this
            // screen) never explains *why* invite-code creation failed.
            inviteCodeState = .error(Self.inviteCodeErrorMessage(for: error))
        } catch let error as CircleInviteCodeError {
            inviteCodeState = .error(error.displayMessage)
        } catch {
            inviteCodeState = .error("We couldn't create an invite code. Please try again.")
        }
    }

    /// Maps a `CircleSharingError` into an invite-code-specific, actionable
    /// message. Transient failures (network/rate-limit/service-unavailable)
    /// keep `CircleSharingError.displayMessage`'s existing "try again"
    /// framing unchanged — retrying is still the right next step for those.
    /// Account-unavailable failures get a message specific to *why* the
    /// account can't be used right now, so the user knows what to actually
    /// go do about it.
    private static func inviteCodeErrorMessage(for error: CircleSharingError) -> String {
        guard case .iCloudAccountUnavailable(let availability) = error else {
            return error.displayMessage
        }
        switch availability {
        case .noAccount:
            return "Sign in to iCloud in Settings to create an invite code."
        case .restricted:
            return "iCloud is restricted on this device, so you can't create an invite code right now."
        case .unknown:
            return "We couldn't check your iCloud status. Please try again."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again shortly."
        case .available:
            // Unreachable: `.iCloudAccountUnavailable` is only ever thrown
            // when `allowsSharing` is false, which excludes `.available`.
            return error.displayMessage
        }
    }

    /// Revokes the current invite code. On failure, the active code stays
    /// displayed (state is not changed to `.error`) so the user can simply
    /// try revoking again — revocation failure must remain retryable.
    func revokeInviteCode() async {
        guard let currentInviteCode else { return }
        isRevokingInviteCode = true
        defer { isRevokingInviteCode = false }

        do {
            try await revokeCircleInviteCodeUseCase.execute(code: currentInviteCode)
            self.currentInviteCode = nil
            inviteCodeState = .revoked
        } catch let error as CircleInviteCodeError {
            actionErrorMessage = error.displayMessage
        } catch {
            actionErrorMessage = "We couldn't revoke this code. Please try again."
        }
    }

    /// Called by the View after it has copied the formatted code to the
    /// system pasteboard — pure state, no platform access here.
    func markInviteCodeCopied() {
        didCopyInviteCode = true
    }

    private static func display(for details: CircleInviteCodeDetails, now: Date) -> CircleInviteCodeDisplay {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return CircleInviteCodeDisplay(
            formattedCode: details.code.formatted,
            shareURL: details.shareURL,
            expiresAtLabel: "Expires \(formatter.string(from: details.expiresAt))"
        )
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
            case .feedLocked, .momentNotFound, .commentNotFound, .notCommentAuthor, .pendingDraftCorrupted, .membershipFull,
                 .diaryEntryNotFound, .notDiaryEntryAuthor, .diaryCommentNotFound, .diaryEntryCorrupted:
                return "Something went wrong. Please try again."
            }
        }
        if let sharingError = error as? CircleSharingError {
            return sharingError.displayMessage
        }
        return "Something went wrong. Please try again."
    }
}
