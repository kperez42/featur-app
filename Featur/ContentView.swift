// ContentView.swift - REPLACE ENTIRE FILE
import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var presenceUpdateTimer: Timer?

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

            NavigationStack { EnhancedProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppStateManager.Tab.profile)
        }
        .tint(AppTheme.accent)
        .onAppear {
            startPresenceUpdates()
        }
        .onDisappear {
            stopPresenceUpdates()
        }
    }

    // MARK: - Presence Updates

    /// Start background presence updates to keep user marked as "online"
    private func startPresenceUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Update presence immediately
        Task {
            await PresenceManager.shared.updatePresence(userId: userId)
        }

        // Schedule periodic updates every 3 minutes (to stay within 5 minute window)
        presenceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { _ in
            Task {
                await PresenceManager.shared.updatePresence(userId: userId)
                print("🟢 Updated presence - keeping user online")
            }
        }
    }

    /// Stop presence updates when app goes to background
    private func stopPresenceUpdates() {
        presenceUpdateTimer?.invalidate()
        presenceUpdateTimer = nil
    }
}
