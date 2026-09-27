import UIKit

/// Loads the small, app-created demo image bundled in the asset catalog
/// (`DemoCheckInPhoto` — a simple original illustration, not a photo of any
/// real person or a third-party asset) for the Debug-only "Simulate
/// Friend Check-in" workflow. Never a network fetch, never CloudKit.
struct BundledDemoCheckInImageProvider: DemoCheckInImageProviding {
    func loadImageData() -> Data? {
        UIImage(named: "DemoCheckInPhoto")?.jpegData(compressionQuality: 0.9)
    }
}
