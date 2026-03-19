import SwiftUI

/// Main tab bar matching BottomNav: 홈, 공동구매, 장바구니, MY
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("홈")
            }
            .tag(0)

            NavigationStack {
                GroupListView()
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text("공동구매")
            }
            .tag(1)

            NavigationStack {
                CartView()
            }
            .tabItem {
                Image(systemName: "cart.fill")
                Text("장바구니")
            }
            .tag(2)

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text("MY")
            }
            .tag(3)
        }
        .tint(.nsPrimary)
    }
}
