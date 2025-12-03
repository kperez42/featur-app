import SwiftUI
import AuthenticationServices

struct AuthGateView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {

        Group {
            if auth.user == nil {

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
        .onChange(of: auth.user) { 
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
