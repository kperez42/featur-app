import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.user == nil {
                GuestProfileSignIn()   // Sign in lives here (Profile tab only)
            } else {
                SignedInProfile()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

// MARK: - Guest (not signed in)
private struct GuestProfileSignIn: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            Text("Welcome to FEATUR")
                .font(.largeTitle).bold()

            Text("Sign in to save your profile, sync messages, and be featured.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            // Native Apple button wired to the same VM (nonce stays consistent)
            SignInWithAppleButton(.signIn) { request in
                let req = auth.makeAppleRequest()
                request.requestedScopes = req.requestedScopes ?? []
                request.nonce = req.nonce
            } onCompletion: { result in
                Task { await auth.handleApple(result: result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let msg = auth.errorMessage, !msg.isEmpty {
                Text(msg)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }
}


private struct SignedInProfile: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var appleAnon: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Avatar / Header
            ZStack {
                Circle().fill(.purple.opacity(0.15))
                Text(initials(from: displayName.isEmpty ? email : displayName))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
            }
            .frame(width: 96, height: 96)

            VStack(spacing: 6) {
                Text(displayName.isEmpty ? "Creator" : displayName)
                    .font(.title2).bold()
                if !email.isEmpty { Text(email).foregroundStyle(.secondary) }
                if appleAnon {
                    Text("Signed in with Apple (private relay email)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // Actions
            VStack(spacing: 12) {
                Button {
                    Task { await auth.signOut() }     // now resolves (method exists)
                } label: {
                    SwiftUI.Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                if let uid = FirebaseAuth.Auth.auth().currentUser?.uid {
                    Text("UID: \(uid)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .onAppear { loadUser() }   // ✅ correct usage
    }

    private func loadUser() {
        let u = FirebaseAuth.Auth.auth().currentUser
        displayName = u?.displayName ?? ""
        email = u?.email ?? ""
        if let provider = u?.providerData.first(where: { $0.providerID == "apple.com" }),
           let mail = provider.email, mail.contains("privaterelay.appleid.com") {
            appleAnon = true
        } else {
            appleAnon = false
        }
    }

    // 👇 keep this INSIDE the struct (fixes your stray-brace issue)
    private func initials(from text: String) -> String {
        let parts = text.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        if letters.isEmpty, let first = text.first { return String(first).uppercased() }
        return letters.map { String($0).uppercased() }.joined()
    }
}
