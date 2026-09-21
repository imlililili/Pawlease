//
//  PawleaseApp.swift
//  Pawlease
//
//  Created by Emily on 22/9/2026.
//

import SwiftUI

@main
struct PawleaseApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
