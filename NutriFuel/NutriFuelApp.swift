//
//  NutriFuelApp.swift
//  NutriFuel
//
//  Created by Vincas Anikevičius on 05/02/2025.
//

import SwiftUI

@main
struct NutriFuelApp: App {
    @StateObject var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()  // Your main view with tabs
                .environmentObject(appData)
        }
    }
}
