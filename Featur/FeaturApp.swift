import SwiftUI
import FirebaseAuth
@main
struct FeaturApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthViewModel()
    @StateObject private var appState = AppStateManager()
    
    @State private var showLaunch = true // controls the splash
    
    var body: some Scene {
        
        WindowGroup {
            ZStack {
                
                // your main app content
                AuthGateView()
                    .environmentObject(auth)
                    .environmentObject(appState)
                    .opacity(showLaunch ? 0 : 1) // hide while splash shows
                
                // your animated launch splash
                if showLaunch {
                    LaunchView()
                        .transition(.opacity)
                    
                }
            }
            .onAppear {
                

                //  hide the splash after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunch = false
                    }
                }
            }
        }
    }
}
