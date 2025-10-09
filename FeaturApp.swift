import SwiftUI

@main
struct FeaturApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthViewModel()
    @StateObject private var appState = AppStateManager()
    
    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(auth)
                .environmentObject(appState)
        }
    }
}
