import SwiftUI
import AuthenticationServices

struct AuthGateView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showAppleSheet = false

    var body: some View {
        Group {
            if auth.user != nil {
                //  User already logged in → go to main app
                ContentView()
            } else {
                //  Default screen = your Firebase email/password login
                NavigationStack {
                    LoginView()
                        .toolbar {
                            // Optional button to show Apple Sign-In
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
                            //
                            AppleSignInSheet(auth: auth)
                        }
                }
            }
        }
    }
}

/// Small wrapper for apple sign in 
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
