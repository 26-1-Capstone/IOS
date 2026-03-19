import SwiftUI

@main
struct NutriShareApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var cartStore = CartStore()
    @StateObject private var wishlistStore = WishlistStore()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(cartStore)
                    .environmentObject(wishlistStore)
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(cartStore)
                    .environmentObject(wishlistStore)
            }
            
        }
    }
}
