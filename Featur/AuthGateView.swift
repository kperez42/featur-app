import SwiftUI
import AuthenticationServices

struct AuthGateView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.user != nil {
                // your existing 5-tab UI
                ContentView() // ← unchanged tabs you already have
            } else {
                SignInScreen()
            }
        }
    }
}

private struct SignInScreen: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Welcome to FEATUR")
                .font(.largeTitle).bold()
            Text("Sign in to continue")
                .foregroundStyle(.secondary)

            // ✅ Uses the SAME AuthViewModel instance to build the request (nonce stays consistent)
            AppleButtonExact(
                makeRequest: { auth.makeAppleRequest() },
                onCompletion: { result in
                    Task { await auth.handleApple(result: result) }
                }
            )
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let err = auth.errorMessage {
                Text(err)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }
}

// Exact-request Apple button wrapper to preserve our nonce
struct AppleButtonExact: UIViewRepresentable {
    let makeRequest: () -> ASAuthorizationAppleIDRequest
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let b = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        b.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        return b
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(makeRequest: makeRequest, onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let makeRequest: () -> ASAuthorizationAppleIDRequest
        let onCompletion: (Result<ASAuthorization, Error>) -> Void

        init(makeRequest: @escaping () -> ASAuthorizationAppleIDRequest,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.makeRequest = makeRequest
            self.onCompletion = onCompletion
        }

        @objc func tap() {
            let request = makeRequest() // ← request/nonce from the SAME AuthViewModel
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        // Provide a presentation anchor for the Apple sheet
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.keyWindow {
                return window
            }
            return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
        }

        // Delegate callbacks
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
    }
}

// Small helper for iOS 15+ to get keyWindow from a scene
private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } }
}
