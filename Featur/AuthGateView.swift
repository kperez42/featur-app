import SwiftUI
import AuthenticationServices

struct AuthGateView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showAppleSheet = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        Group {
            if let user = auth.user, user.isEmailVerified {
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
                } else if auth.userProfile == nil {
                    // No profile exists - show setup flow
                    ProfileSetupView()
                } else {
                    // Profile exists - show main app
                    ContentView()
                }
            } else {
                NavigationStack(path: $navigationPath) {
                    LoginView(navigationPath: $navigationPath) // Pass navigationPath
                        .navigationDestination(for: String.self) { destination in
                            if destination == "RegistrationView" {
                                RegistrationView(navigationPath: $navigationPath) // Pass navigationPath
                            } else if destination == "LoginView" {
                                LoginView(navigationPath: $navigationPath) // Pass navigationPath
                            } else if destination == "VerifyEmailView" {
                                VerifyEmailView(email: "") // Update to pass email if needed
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showAppleSheet = true
                                } label: {
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .sheet(isPresented: $showAppleSheet) {
                            AppleSignInSheet(auth: auth)
                        }
                }
                .onChange(of: auth.user) { _, newUser in
                    if newUser == nil {
                        navigationPath = NavigationPath() // Reset to LoginView
                        navigationPath.append("LoginView")
                    }
                }
            }
        }
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
