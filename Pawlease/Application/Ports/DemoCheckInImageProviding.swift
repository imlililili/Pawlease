import Foundation

/// Supplies the small, bundled, app-created demo image used by the
/// Debug-only `SimulateFriendCheckInUseCase`. A protocol — not a direct
/// `UIImage` call — so the Use Case itself never needs to import UIKit, and
/// so unit tests can inject fixed bytes instead of touching the real asset
/// catalog.
protocol DemoCheckInImageProviding: Sendable {
    func loadImageData() -> Data?
}
