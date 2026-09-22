//
//  PawleaseApp.swift
//  Pawlease
//
//  Created by Emily on 22/9/2026.
//

import SwiftUI

@main
struct PawleaseApp: App {
    @UIApplicationDelegateAdaptor(PawleaseAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await acceptPendingInvitationIfNeeded() }
                    }
                }
        }
    }

    /// The application lifecycle (foregrounding after
    /// `application(_:userDidAcceptCloudKitShareWith:)` staged an
    /// invitation) is what triggers acceptance — never a ViewModel calling
    /// CloudKit directly. Failure here is reported via `print` only,
    /// deliberately: existing local Circle data is never touched by a
    /// failed acceptance attempt.
    private func acceptPendingInvitationIfNeeded() async {
        guard ShareAcceptanceCoordinator.shared.hasPendingInvitation else { return }
        do {
            try await dependencies.acceptCircleInvitationUseCase.execute()
        } catch {
            print("Pawlease: failed to accept pending Circle invitation: \(error)")
        }
    }
}
