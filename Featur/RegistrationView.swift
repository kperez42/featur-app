import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct RegistrationView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Group {
                        inputField("Full Name", text: $name)
                        inputField("Email", text: $email)
                        inputField("Password", text: $password, secure: true)
                        inputField("Confirm Password", text: $confirmPassword, secure: true)
                    }
                    
                    // Firebase auth runs here
                    Button {
                        Task { await register() }
                    } label: {
                        Text(isLoading ? "Creating..." : "Sign Up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.top, 12)
                    
                    Text("By signing up, you agree to our Terms & Privacy Policy.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(32)
            }
        }
    }
    
    func inputField(_ placeholder: String, text: Binding<String>, secure: Bool = false) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
                    .textContentType(.oneTimeCode)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
        }
        .padding()
        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .foregroundColor(.white)
    }

    
    func register() async {
        isLoading = true
        do {
            // Create account
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            
            // Save to Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(uid).setData([
                "name": name,
                "email": email,
                "createdAt": Timestamp(date: Date())
            ])
            
            // Send verification email ONCE at registration
            try await result.user.sendEmailVerification()
            print("Verification email sent to \(email)")
            
            // sign out automatically so they log in after verifying
            try Auth.auth().signOut()
            
        } catch {
            print("Registration failed: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

