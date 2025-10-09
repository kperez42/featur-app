import SwiftUI

@main
struct FeaturApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var auth = AuthViewModel()

  var body: some Scene {
    WindowGroup {
      AuthGateView()
        .environmentObject(auth)
    }
  }
}
