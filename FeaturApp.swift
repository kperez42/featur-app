import SwiftUI
import GoogleMobileAds

@main
struct FeaturApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthViewModel()
    @StateObject private var appState = AppStateManager()
    @StateObject private var adManager = AdManager() // ✅ Add this
    
    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(auth)
                .environmentObject(appState)
                .environmentObject(adManager) // ✅ Add this
        }
    }
}
