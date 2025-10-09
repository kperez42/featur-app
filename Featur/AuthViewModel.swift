import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseCore     // 👈 Needed for FirebaseApp
import FirebaseAuth
import os.log

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    private var currentNonce: String?

    private let log = Logger(subsystem: "featur-app.Featur", category: "Auth")

    override init() {
        super.init()
        // Keep local state in sync with Firebase Auth
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
        self.dumpEnvironmentOnce()
    }

    // MARK: - Apple Sign-In

    /// Build the Apple ID request with a cryptographic nonce.
    func makeAppleRequest() -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        log.debug("🧪 makeAppleRequest(): nonce set, scopes=\(String(describing: request.requestedScopes))")
        return request
    }

    /// Handle the Apple auth result, exchange for Firebase credential, and sign in.
    func handleApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let err):
            let ns = err as NSError
            self.errorMessage = "Apple auth failed: \(ns.domain) code=\(ns.code) \(ns.localizedDescription)"
            logAppleNSError(ns, context: "ASAuthorizationController failed")
            return

        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                self.errorMessage = "No AppleID credential returned."
                log.error("❌ handleApple: No ASAuthorizationAppleIDCredential")
                return
            }

            // Helpful: check credential state right away (often reveals -7071/-7022 root cause)
            do {
                try await checkCredentialState(appleIDCredential.user)
            } catch {
                let ns = error as NSError
                logAppleNSError(ns, context: "checkCredentialState threw")
            }

            guard let nonce = currentNonce else {
                self.errorMessage = "Invalid state: missing login request nonce."
                log.error("❌ Missing nonce in handleApple success path")
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                self.errorMessage = "Unable to fetch identity token from Apple."
                log.error("❌ No identityToken in Apple credential")
                return
            }

            log.debug("🧪 Received Apple credential. user=\(appleIDCredential.user, privacy: .private), tokenLength=\(appleIDToken.count)")

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName // you can pass nil if you want
            )

            do {
                let result = try await Auth.auth().signIn(with: credential)
                self.user = result.user
                self.errorMessage = nil
                log.debug("✅ Firebase sign-in success. uid=\(result.user.uid, privacy: .private)")
            } catch {
                let ns = error as NSError
                self.errorMessage = "Firebase sign-in failed: \(ns.domain) code=\(ns.code) \(ns.localizedDescription)"
                logFirebaseNSError(ns, context: "signIn(with: Apple) failed")
            }
        }
    }

    // MARK: - Helpers / Diagnostics
    private func dumpEnvironmentOnce() {
        let bundleID = Bundle.main.bundleIdentifier ?? "nil"
        log.debug("🧪 Env: BundleID=\(bundleID)")

        #if DEBUG
        log.debug("🧪 Build: DEBUG")
        #else
        log.debug("🧪 Build: RELEASE")
        #endif

        if let opts = FirebaseApp.app()?.options {
            let b = opts.bundleID ?? "nil"
            let p = opts.projectID
            let a = opts.googleAppID
            let message = "🧪 Firebase options: bundleID=\(b), projectID=\(p), appID=\(a)"
            log.debug("\(message, privacy: .public)")
        } else {
            log.error("❌ FirebaseApp.options is nil (FirebaseApp.configure() not run or failed)")
        }
    }


    private func logAppleNSError(_ ns: NSError, context: String) {
        // Common Apple domains/codes we see: com.apple.AuthenticationServices.AuthorizationError (1000)
        // AKAuthenticationErrorDomain: -7022 (account not found / auth canceled), -7071 (SIWA not available / entitlements)
        log.error("❌ \(context): domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
        if !ns.userInfo.isEmpty {
            log.error("❌ userInfo=\(String(describing: ns.userInfo))")
        }
        self.errorMessage = "\(context): \(ns.domain) code=\(ns.code)"
    }

    private func logFirebaseNSError(_ ns: NSError, context: String) {
        log.error("❌ \(context): domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
        if !ns.userInfo.isEmpty {
            log.error("❌ userInfo=\(String(describing: ns.userInfo))")
        }
    }

    /// Check Apple credential state to surface environment errors (-7071 etc.)
    private func checkCredentialState(_ userID: String) async throws {
        return try await withCheckedThrowingContinuation { cont in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, error in
                if let error { cont.resume(throwing: error); return }
                switch state {
                case .authorized:
                    self.log.debug("🧪 credentialState: authorized")
                    cont.resume()
                case .revoked:
                    self.log.error("❌ credentialState: revoked")
                    cont.resume()
                case .notFound:
                    self.log.error("❌ credentialState: notFound (sim/device Apple ID not linked)")
                    cont.resume()
                case .transferred:
                    self.log.error("❌ credentialState: transferred")
                    cont.resume()
                @unknown default:
                    self.log.error("❌ credentialState: unknown \(state.rawValue)")
                    cont.resume()
                }
            }
        }
    }

    // MARK: - Nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let err = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if err != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with \(err)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}
