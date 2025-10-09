import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    private var currentNonce: String?

    init() {
        // Keep local state in sync with Firebase Auth
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    // MARK: - Apple Sign-In

    /// Build the Apple ID request with a cryptographic nonce.
    func makeAppleRequest() -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        return request
    }

    /// Handle the Apple auth result, exchange for Firebase credential, and sign in.
    func handleApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let err):
            self.errorMessage = err.localizedDescription

        case .success(let authorization):
            guard
                let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let tokenData = apple.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                self.errorMessage = "Apple sign-in failed."
                return
            }

            do {
                // Preferred API: capture fullName on first login if Apple provides it
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idToken,
                    rawNonce: nonce,
                    fullName: apple.fullName
                )
                let authResult = try await Auth.auth().signIn(with: credential)

                // Optionally set Firebase displayName the first time (Apple only provides fullName once)
                if let name = apple.fullName, (name.givenName != nil || name.familyName != nil) {
                    let display = [name.givenName, name.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    if !display.isEmpty {
                        let change = authResult.user.createProfileChangeRequest()
                        change.displayName = display
                        try await change.commitChanges()
                        self.user = Auth.auth().currentUser
                    }
                }

            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess { fatalError("Unable to generate nonce.") }
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }
}
