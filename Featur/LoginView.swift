import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var show = false
    @FocusState private var focused: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image("FeaturLogo")
                    .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        


                Text("")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.subheadline)

                VStack(spacing: 18) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .focused($focused, equals: .email)
                        .padding()
                        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .textContentType(.oneTimeCode)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .focused($focused, equals: .password)
                        .padding()
                        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)

                Button {
                    Task { await signIn() }
                } label: {
                    Text(isLoading ? "Signing In..." : "Log In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)

                // Forgot Password
                Button("Forgot Password?") {
                    Task { await resetPassword() }
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 6)

                // Create Account → RegistrationView
                NavigationLink {
                    RegistrationView()
                } label: {
                    Text("Create an account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                                Spacer()
                            }
                            .padding(.vertical)
                        }
                    }
    func resetPassword() async {
        guard !email.isEmpty else {
            print("Please enter your email first.")
            return
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("Password reset email sent to \(email)")
        } catch {
            print("Failed to send reset email: \(error.localizedDescription)")
        }
    }

    func signIn() async {
        isLoading = true
        do{
            try await Auth.auth().signIn(withEmail: email, password: password )
            print("Successfully logged in as \(email)")
        }catch {
            print("Sign in failed: \(error.localizedDescription)")
        }
        isLoading = false
        
    }
}

