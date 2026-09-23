//
//  ShareViewController.swift
//  PawleaseShareExtension
//
//  Created by Emily on 23/9/2026.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// The Share Extension's entry point (`NSExtensionPrincipalClass`). Hosts
/// `ShareComposeView` via `UIHostingController` rather than
/// `SLComposeServiceViewController`, for full control over the loading/
/// success/error states the task requires. Only ever touches
/// `ShareInboxStoring` (via `ShareComposeViewModel`) — never Core Data,
/// CloudKit, or `NSPersistentCloudKitContainer`.
final class ShareViewController: UIViewController {
    private let viewModel = ShareComposeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingController = UIHostingController(
            rootView: ShareComposeView(
                viewModel: viewModel,
                onFinish: { [weak self] in self?.finish() },
                onCancel: { [weak self] in self?.cancel() }
            )
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        Task { await viewModel.loadImage(from: firstImageItemProvider()) }
    }

    /// Finds the first attachment that conforms to `UTType.image` across
    /// every input item. The activation rule already restricts the share
    /// sheet to a single image, but this stays defensive rather than force-
    /// unwrapping in case an attachment array is empty or malformed.
    private func firstImageItemProvider() -> NSItemProvider? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                return provider
            }
        }
        return nil
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancel() {
        let error = NSError(domain: "com.lili.Pawlease.PawleaseShareExtension", code: NSUserCancelledError)
        extensionContext?.cancelRequest(withError: error)
    }
}
