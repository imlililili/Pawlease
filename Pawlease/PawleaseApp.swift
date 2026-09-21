//
//  PawleaseApp.swift
//  Pawlease
//
//  Created by Emily on 22/9/2026.
//

import SwiftUI
import CoreData

@main
struct PawleaseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
