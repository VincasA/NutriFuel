//
//  NutriFuelApp.swift
//  NutriFuel
//
//  Created by Vincas Anikevičius on 05/02/2025.
//

import SwiftUI

@main
struct NutriFuelApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
