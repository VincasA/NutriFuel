import SwiftUI

@main
struct NutriFuelApp: App {
    @StateObject private var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appData)
        }
    }
}
