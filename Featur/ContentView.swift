// ContentView.swift - REPLACE ENTIRE FILE
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack { EnhancedHomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppStateManager.Tab.home)

            NavigationStack { EnhancedDiscoverView() }
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }
                .tag(AppStateManager.Tab.discover)

            NavigationStack { FeaturedView() }
                .tabItem { Label("FEATUREd", systemImage: "star.fill") }
                .tag(AppStateManager.Tab.featured)

            NavigationStack { EnhancedMessagesView() }
                .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppStateManager.Tab.messages)

            NavigationStack { PerfectProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppStateManager.Tab.profile)
        }
        .tint(AppTheme.accent)
    }
}
