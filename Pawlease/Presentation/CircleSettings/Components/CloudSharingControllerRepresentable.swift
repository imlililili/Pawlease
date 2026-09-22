import SwiftUI
import UIKit

/// Thin SwiftUI wrapper around an already-constructed `UICloudSharingController`.
/// The controller itself (and its delegate) is built by the Infrastructure-
/// layer `CloudSharingControllerProviding` adapter — this view just
/// presents it. Apple's native sharing UI is used as-is; no custom
/// invitation UI replaces it.
struct CloudSharingControllerRepresentable: UIViewControllerRepresentable {
    let controller: UICloudSharingController

    func makeUIViewController(context: Context) -> UICloudSharingController {
        controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
}
