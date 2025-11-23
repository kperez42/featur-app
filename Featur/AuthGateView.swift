import SwiftUI
import AuthenticationServices

struct AuthGateView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showAppleSheet = false

    var body: some View {
        Group {

            // 1) Not logged in → Login/Register flow
            if auth.user == nil {
                NavigationStack(path: $navigationPath) {
                    LoginView(navigationPath: $navigationPath)
                        .navigationDestination(for: String.self) { destination in
                            switch destination {
                            case "RegistrationView":
                                RegistrationView(navigationPath: $navigationPath)
                            case "VerifyEmailView":
                                VerifyEmailView()
                            default:
                                EmptyView()
                            }
                        }
                }
            }

            // 2) Logged in but not verified
            else if !auth.isEmailVerified {
                VerifyEmailView()
            }

            // 3) Logged in + verified but no Firestore profile
            else if auth.needsProfileSetup {
                ProfileCreationFlow(viewModel: ProfileViewModel())
            }

            // 4) Fully onboarded
            else {
                ContentView()
            }
        }
        .onAppear {
            Task { await auth.refreshUserState() }
        }
        .onChange(of: auth.user) { _ in
            Task { await auth.refreshUserState() }
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
