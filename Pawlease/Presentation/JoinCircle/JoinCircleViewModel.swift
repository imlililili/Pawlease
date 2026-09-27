import Foundation
import Observation

/// Coordinates the "Join a Circle" workflow: normalizes and resolves a
/// typed invite code, then hands the resolved CKShare URL to an injected
/// platform adapter to open — that open is what actually triggers Apple's
/// native CKShare acceptance flow. This ViewModel never touches CloudKit or
/// UIKit directly.
@MainActor
@Observable
final class JoinCircleViewModel {
    enum ResolveState: Equatable {
        case idle
        case resolving
        case opening
        case error(String)
    }

    var codeInput: String = ""
    private(set) var resolveState: ResolveState = .idle

    var canSubmit: Bool {
        !codeInput.trimmingCharacters(in: .whitespaces).isEmpty && resolveState != .resolving && resolveState != .opening
    }

    private let resolveCircleInviteCodeUseCase: ResolveCircleInviteCodeUseCase
    private let shareURLOpener: ShareURLOpening

    init(resolveCircleInviteCodeUseCase: ResolveCircleInviteCodeUseCase, shareURLOpener: ShareURLOpening) {
        self.resolveCircleInviteCodeUseCase = resolveCircleInviteCodeUseCase
        self.shareURLOpener = shareURLOpener
    }

    func joinCircle() async {
        resolveState = .resolving
        do {
            let details = try await resolveCircleInviteCodeUseCase.execute(rawInput: codeInput)
            resolveState = .opening
            let opened = await shareURLOpener.open(details.shareURL)
            resolveState = opened
                ? .idle
                : .error("We couldn't open the invitation. Please try again.")
        } catch let error as CircleInviteCodeError {
            resolveState = .error(error.displayMessage)
        } catch {
            resolveState = .error("We couldn't join that Circle. Please try again.")
        }
    }
}
