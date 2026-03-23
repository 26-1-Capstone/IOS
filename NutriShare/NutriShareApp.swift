import SwiftUI

@main
struct NutriShareApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var cartStore = CartStore()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(cartStore)
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(cartStore)
            }
            
        }
    }
}
