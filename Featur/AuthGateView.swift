import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AuthGateView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {

        Group {
            // Allow Apple Sign-In users (they are inherently verified) or verified email users
            if let user = auth.user, (user.isEmailVerified || isAppleSignIn(user: user)) {
                // Check if user has completed profile setup
                if auth.isLoadingProfile {
                    // Show loading while checking for profile
                    ZStack {
                        AppTheme.gradient.ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Loading your profile...")
                                .foregroundStyle(.white)
                                .font(.subheadline)
                        }
                    }
                } else if auth.userProfile == nil || auth.needsProfileSetup {
                    // No profile exists or needs setup - show setup flow
                    ProfileSetupView()
                } else {
                    // Profile exists - show main app
                    ContentView()
                }
            } else if auth.user == nil {
                NavigationStack(path: $navigationPath) {
                    LoginView(navigationPath: $navigationPath)
                        .navigationDestination(for: String.self) { destination in
                            switch destination {
                            case "RegistrationView":
                                RegistrationView(navigationPath: $navigationPath)
                            default:
                                EmptyView()
                            }
                        }
                }

            } else if !auth.isEmailVerified {

                VerifyEmailView(navigationPath: $navigationPath)

            } else if auth.needsProfileSetup {

                ProfileCreationFlow(viewModel: ProfileViewModel())

            } else {

                ContentView()
            }
        }
        .onChange(of: auth.user) { _, _ in
            Task { await auth.refreshUserState() }
        }
    }

    /// Check if user signed in with Apple (they are inherently verified)
    private func isAppleSignIn(user: FirebaseAuth.User) -> Bool {
        return user.providerData.contains { $0.providerID == "apple.com" }
    }
}




/// Small wrapper for Apple Sign-In
struct AppleSignInSheet: View {
    @ObservedObject var auth: AuthViewModel
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign in with Apple")
                .font(.headline)
                .foregroundStyle(.white)

            SignInWithAppleButton(.signIn) { request in
                let req = auth.makeAppleRequest()
                request.requestedScopes = req.requestedScopes ?? []
                request.nonce = req.nonce
            } onCompletion: { result in
                Task { await auth.handleApple(result: result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
        }
        .padding()
        .background(AppTheme.gradient.ignoresSafeArea())
    }
}
