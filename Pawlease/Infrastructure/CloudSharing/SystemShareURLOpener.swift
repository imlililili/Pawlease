import UIKit

/// Opens a URL via `UIApplication.shared.open(_:)` — the live implementation
/// of `ShareURLOpening`.
final class SystemShareURLOpener: ShareURLOpening {
    @MainActor
    func open(_ url: URL) async -> Bool {
        await UIApplication.shared.open(url)
    }
}
