import SwiftUI
import AuthenticationServices

struct AuthGateView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.user != nil {
                // ✅ Show your 5-tab app after login
                ContentView()
            } else {
                // 🔐 Sign-in screen
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        let req = auth.makeAppleRequest()
                        request.requestedScopes = req.requestedScopes ?? []
                        request.nonce = req.nonce
                    } onCompletion: { result in
                        Task { await auth.handleApple(result: result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)

                    if let msg = auth.errorMessage, !msg.isEmpty {
                        Text(msg)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
    }
}
